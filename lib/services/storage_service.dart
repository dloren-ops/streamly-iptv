import 'package:hive_flutter/hive_flutter.dart';
import '../models/channel.dart';

/// Local storage service using Hive for fast, lightweight persistence
class StorageService {
  static const String _channelsBox = 'channels';
  static const String _favoritesBox = 'favorites';
  static const String _settingsBox = 'settings';
  static const String _playlistsBox = 'playlists';
  static const String _credentialsBox = 'credentials';

  /// Initialize Hive storage
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_channelsBox);
    await Hive.openBox<String>(_favoritesBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox<String>(_playlistsBox);
    await Hive.openBox(_credentialsBox);
  }

  // ─── Xtream Credentials ─────────────────────────────────────

  /// Save Xtream login credentials (for the refresh/update feature)
  static Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final box = Hive.box(_credentialsBox);
    await box.put('server_url', serverUrl);
    await box.put('username', username);
    await box.put('password', password);
  }

  /// Get saved credentials, or null if none stored
  static Map<String, String>? getCredentials() {
    final box = Hive.box(_credentialsBox);
    final serverUrl = box.get('server_url');
    final username = box.get('username');
    final password = box.get('password');
    if (serverUrl == null || username == null || password == null) {
      return null;
    }
    return {
      'server_url': serverUrl,
      'username': username,
      'password': password,
    };
  }

  /// Save the resolved M3U source URL (Xtream-built or direct)
  static Future<void> saveSourceUrl(String url) async {
    final box = Hive.box(_credentialsBox);
    await box.put('source_url', url);
  }

  /// Get the saved source URL (used by the refresh button)
  static String? getSourceUrl() {
    final box = Hive.box(_credentialsBox);
    return box.get('source_url');
  }

  /// Clear saved credentials (logout)
  static Future<void> clearCredentials() async {
    await Hive.box(_credentialsBox).clear();
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return getSourceUrl() != null;
  }

  // ─── Channels ───────────────────────────────────────────────

  /// Save channels to local cache
  static Future<void> saveChannels(List<Channel> channels) async {
    final box = Hive.box(_channelsBox);
    await box.clear();
    final data = channels.map((c) => c.toJson()).toList();
    await box.put('channel_list', data);
    await box.put('last_updated', DateTime.now().toIso8601String());
  }

  /// Load channels from local cache
  static List<Channel> loadChannels() {
    final box = Hive.box(_channelsBox);
    final data = box.get('channel_list');
    if (data == null) return [];

    final favorites = getFavoriteIds();
    return (data as List).map((json) {
      final channel = Channel.fromJson(Map<String, dynamic>.from(json));
      channel.isFavorite = favorites.contains(channel.id);
      return channel;
    }).toList();
  }

  /// Check if cache is still valid (less than 1 hour old)
  static bool isCacheValid() {
    final box = Hive.box(_channelsBox);
    final lastUpdated = box.get('last_updated');
    if (lastUpdated == null) return false;

    final date = DateTime.parse(lastUpdated);
    return DateTime.now().difference(date).inHours < 1;
  }

  // ─── Favorites ──────────────────────────────────────────────

  /// Add channel to favorites
  static Future<void> addFavorite(String channelId) async {
    final box = Hive.box<String>(_favoritesBox);
    await box.put(channelId, channelId);
  }

  /// Remove channel from favorites
  static Future<void> removeFavorite(String channelId) async {
    final box = Hive.box<String>(_favoritesBox);
    await box.delete(channelId);
  }

  /// Get all favorite channel IDs
  static Set<String> getFavoriteIds() {
    final box = Hive.box<String>(_favoritesBox);
    return box.values.toSet();
  }

  /// Check if a channel is favorite
  static bool isFavorite(String channelId) {
    final box = Hive.box<String>(_favoritesBox);
    return box.containsKey(channelId);
  }

  // ─── Playlists ──────────────────────────────────────────────

  /// Save a playlist URL
  static Future<void> savePlaylistUrl(String name, String url) async {
    final box = Hive.box<String>(_playlistsBox);
    await box.put(name, url);
  }

  /// Get all saved playlist URLs
  static Map<String, String> getPlaylists() {
    final box = Hive.box<String>(_playlistsBox);
    return Map<String, String>.from(box.toMap());
  }

  /// Delete a playlist
  static Future<void> deletePlaylist(String name) async {
    final box = Hive.box<String>(_playlistsBox);
    await box.delete(name);
  }

  // ─── Settings ───────────────────────────────────────────────

  /// Save a setting
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  /// Get a setting
  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await Hive.box(_channelsBox).clear();
    await Hive.box<String>(_favoritesBox).clear();
    await Hive.box<String>(_playlistsBox).clear();
    await Hive.box(_credentialsBox).clear();
  }
}
