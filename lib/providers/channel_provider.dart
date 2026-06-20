import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/epg_program.dart';
import '../services/playlist_service.dart';
import '../services/storage_service.dart';
import '../services/xtream_service.dart';
import '../services/epg_service.dart';

/// State management for channels using Provider pattern
/// This is the "brain" layer - manages state without knowing about UI
class ChannelProvider extends ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  final XtreamService _xtreamService = XtreamService();
  final EpgService _epgService = EpgService();
  bool _disposed = false;

  // ─── State ──────────────────────────────────────────────────
  List<Channel> _allChannels = [];
  List<Channel> _filteredChannels = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  Channel? _currentChannel;
  XtreamAccount? _account;
  bool _isRefreshing = false;

  // ─── Getters ────────────────────────────────────────────────
  List<Channel> get channels => _filteredChannels;
  List<Channel> get allChannels => _allChannels;
  List<Channel> get favorites =>
      _allChannels.where((c) => c.isFavorite).toList();
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Channel? get currentChannel => _currentChannel;
  int get totalChannels => _allChannels.length;
  int get totalFavorites => favorites.length;
  XtreamAccount? get account => _account;
  bool get isRefreshing => _isRefreshing;
  bool get isLoggedIn => StorageService.isLoggedIn();
  bool get hasEpg => _epgService.hasData;

  /// Current program airing on a channel (from EPG)
  EpgProgram? currentProgram(Channel channel) =>
      _epgService.getCurrentProgram(channel.epgChannelId);

  /// Next program on a channel (from EPG)
  EpgProgram? nextProgram(Channel channel) =>
      _epgService.getNextProgram(channel.epgChannelId);

  /// Full upcoming schedule for a channel (from EPG)
  List<EpgProgram> schedule(Channel channel) =>
      _epgService.getSchedule(channel.epgChannelId);

  // ─── Actions ────────────────────────────────────────────────

  /// Load playlist from URL
  Future<void> loadFromUrl(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allChannels = await _playlistService.loadFromUrl(url);
      _categories = PlaylistService.getCategories(_allChannels);
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Error loading playlist: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load playlist from file content
  void loadFromContent(String content) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allChannels = _playlistService.loadFromContent(content);
      _categories = PlaylistService.getCategories(_allChannels);
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Error parsing playlist: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with Xtream Codes credentials (server URL + username + password)
  Future<bool> loginXtream({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate credentials against the server
      _account = await _xtreamService.authenticate(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      // Build the M3U URL and load channels
      final m3uUrl = XtreamService.buildM3UUrl(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      _allChannels = await _playlistService.loadFromUrl(m3uUrl);
      _categories = PlaylistService.getCategories(_allChannels);
      _applyFilters();

      // Persist credentials + source URL for the refresh feature
      await StorageService.saveCredentials(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      await StorageService.saveSourceUrl(m3uUrl);

      _error = null;

      // Load EPG in the background with delay (don't compete with video playback)
      Future.delayed(const Duration(seconds: 30), () {
        if (_disposed) return;
        _loadEpg(
          serverUrl: serverUrl,
          username: username,
          password: password,
        );
      });

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh/update channels from the saved source (the "update" button)
  Future<void> refresh() async {
    final sourceUrl = await StorageService.getSourceUrl();
    if (sourceUrl == null) {
      _error = 'No source to refresh. Please log in first.';
      notifyListeners();
      return;
    }

    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      // Preserve favorites across refresh
      final favoriteIds = StorageService.getFavoriteIds();

      _allChannels = await _playlistService.loadFromUrl(sourceUrl);
      for (final channel in _allChannels) {
        channel.isFavorite = favoriteIds.contains(channel.id);
      }
      _categories = PlaylistService.getCategories(_allChannels);
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = 'Refresh failed: ${e.toString()}';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Logout and clear credentials
  Future<void> logout() async {
    await StorageService.clearCredentials();
    await StorageService.clearAll();
    _allChannels = [];
    _filteredChannels = [];
    _categories = ['All'];
    _account = null;
    notifyListeners();
  }

  /// Try auto-login from saved credentials on app start
  Future<void> tryAutoLogin() async {
    if (!StorageService.isLoggedIn()) return;

    // Load cached channels first for instant startup
    loadFromCache();

    // Then refresh in the background
    await refresh();

    // Load EPG from saved credentials with delay to not compete with playback
    final creds = await StorageService.getCredentials();
    if (creds != null) {
      Future.delayed(const Duration(seconds: 30), () {
        if (_disposed) return;
        _loadEpg(
          serverUrl: creds['server_url']!,
          username: creds['username']!,
          password: creds['password']!,
        );
      });
    }
  }

  /// Load EPG data in the background (non-blocking)
  Future<void> _loadEpg({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    try {
      final epgUrl = EpgService.buildEpgUrl(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      await _epgService.loadFromUrl(epgUrl);
      notifyListeners();
    } catch (_) {
      // EPG is optional; ignore failures silently
    }
  }

  /// Load from local cache
  void loadFromCache() {
    _allChannels = _playlistService.loadFromCache();
    if (_allChannels.isNotEmpty) {
      _categories = PlaylistService.getCategories(_allChannels);
      _applyFilters();
    }
    notifyListeners();
  }

  /// Set search query and filter
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Set selected category and filter
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(Channel channel) async {
    channel.isFavorite = !channel.isFavorite;
    if (channel.isFavorite) {
      await StorageService.addFavorite(channel.id);
    } else {
      await StorageService.removeFavorite(channel.id);
    }
    notifyListeners();
  }

  /// Set current playing channel
  void setCurrentChannel(Channel? channel) {
    _currentChannel = channel;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Private ────────────────────────────────────────────────

  /// Apply category and search filters
  void _applyFilters() {
    var result = _allChannels;

    // Apply category filter
    if (_selectedCategory != 'All') {
      result = PlaylistService.filterByCategory(result, _selectedCategory);
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = PlaylistService.search(result, _searchQuery);
    }

    _filteredChannels = result;
  }
}
