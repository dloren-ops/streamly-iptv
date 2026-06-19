import 'package:flutter/foundation.dart';
import '../models/vod_item.dart';
import '../services/vod_service.dart';
import '../services/storage_service.dart';

/// State management for VOD content (movies & series).
/// Loads lazily — only fetches when the user opens the Movies/Series tabs.
class VodProvider extends ChangeNotifier {
  final VodService _service = VodService();

  // ─── State ──────────────────────────────────────────────────
  List<VodItem> _movies = [];
  List<VodItem> _series = [];
  bool _moviesLoaded = false;
  bool _seriesLoaded = false;
  bool _isLoadingMovies = false;
  bool _isLoadingSeries = false;
  String? _error;

  String _movieQuery = '';
  String _seriesQuery = '';

  // ─── Getters ────────────────────────────────────────────────
  List<VodItem> get movies => _movieQuery.isEmpty
      ? _movies
      : _movies
          .where((m) => m.name.toLowerCase().contains(_movieQuery.toLowerCase()))
          .toList();

  List<VodItem> get series => _seriesQuery.isEmpty
      ? _series
      : _series
          .where((s) => s.name.toLowerCase().contains(_seriesQuery.toLowerCase()))
          .toList();

  bool get isLoadingMovies => _isLoadingMovies;
  bool get isLoadingSeries => _isLoadingSeries;
  String? get error => _error;
  int get totalMovies => _movies.length;
  int get totalSeries => _series.length;

  // ─── Actions ────────────────────────────────────────────────

  /// Load movies (only once unless forced)
  Future<void> loadMovies({bool force = false}) async {
    if (_moviesLoaded && !force) return;
    final creds = await StorageService.getCredentials();
    if (creds == null) return;

    _isLoadingMovies = true;
    _error = null;
    notifyListeners();

    try {
      _movies = await _service.getMovies(
        serverUrl: creds['server_url']!,
        username: creds['username']!,
        password: creds['password']!,
      );
      _moviesLoaded = true;
    } catch (e) {
      _error = 'Error loading movies: ${e.toString()}';
    } finally {
      _isLoadingMovies = false;
      notifyListeners();
    }
  }

  /// Load series (only once unless forced)
  Future<void> loadSeries({bool force = false}) async {
    if (_seriesLoaded && !force) return;
    final creds = await StorageService.getCredentials();
    if (creds == null) return;

    _isLoadingSeries = true;
    _error = null;
    notifyListeners();

    try {
      _series = await _service.getSeries(
        serverUrl: creds['server_url']!,
        username: creds['username']!,
        password: creds['password']!,
      );
      _seriesLoaded = true;
    } catch (e) {
      _error = 'Error loading series: ${e.toString()}';
    } finally {
      _isLoadingSeries = false;
      notifyListeners();
    }
  }

  void searchMovies(String query) {
    _movieQuery = query;
    notifyListeners();
  }

  void searchSeries(String query) {
    _seriesQuery = query;
    notifyListeners();
  }

  /// Build a playable URL for a movie
  Future<String?> movieUrl(VodItem movie) async {
    final creds = await StorageService.getCredentials();
    if (creds == null) return null;
    return VodService.buildMovieUrl(
      serverUrl: creds['server_url']!,
      username: creds['username']!,
      password: creds['password']!,
      movie: movie,
    );
  }

  /// Get episodes of a series grouped by season
  Future<Map<int, List<Episode>>> episodesOf(VodItem series) async {
    final creds = await StorageService.getCredentials();
    if (creds == null) return {};
    return _service.getSeriesEpisodes(
      serverUrl: creds['server_url']!,
      username: creds['username']!,
      password: creds['password']!,
      seriesId: series.id,
    );
  }

  /// Build a playable URL for an episode
  Future<String?> episodeUrl(Episode episode) async {
    final creds = await StorageService.getCredentials();
    if (creds == null) return null;
    return VodService.buildEpisodeUrl(
      serverUrl: creds['server_url']!,
      username: creds['username']!,
      password: creds['password']!,
      episode: episode,
    );
  }

  /// Clear all VOD data (on logout)
  void clear() {
    _movies = [];
    _series = [];
    _moviesLoaded = false;
    _seriesLoaded = false;
    notifyListeners();
  }
}
