import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/channel.dart';

/// Local storage service using Hive for fast, lightweight persistence.
/// Sensitive data (credentials, source URL with password) is kept in the
/// platform secure storage (Keychain / Keystore) instead of plain Hive.
class StorageService {
  static const String _channelsBox = 'channels';
  static const String _favoritesBox = 'favorites';
  static const String _settingsBox = 'settings';
  static const String _playlistsBox = 'playlists';

  /// Secure storage for sensitive credentials
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Secure storage keys
  static const String _kServerUrl = 'server_url';
  static const String _kUsername = 'username';
  static const String _kPassword = 'password';
  static const String _kSourceUrl = 'source_url';

  /// Initialize Hive storage
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_channelsBox);
    await Hive.openBox<String>(_favoritesBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox<String>(_playlistsBox);
  }

  // ─── Xtream Credentials (Secure Storage) ────────────────────

  /// Save Xtream login credentials securely (Keychain / Keystore).
  /// Also stores a non-sensitive "logged in" flag in Hive for fast startup.
  static Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    await _secure.write(key: _kServerUrl, value: serverUrl);
    await _secure.write(key: _kUsername, value: username);
    await _secure.write(key: _kPassword, value: password);
    await Hive.box(_settingsBox).put('logged_in', true);
  }

  /// Get saved credentials, or null if none stored
  static Future<Map<String, String>?> getCredentials() async {
    final serverUrl = await _secure.read(key: _kServerUrl);
    final username = await _secure.read(key: _kUsername);
    final password = await _secure.read(key: _kPassword);
    if (serverUrl == null || username == null || password == null) {
      return null;
    }
    return {
      'server_url': serverUrl,
      'username': username,
      'password': password,
    };
  }

  /// Save the resolved M3U source URL (contains password, so kept secure)
  static Future<void> saveSourceUrl(String url) async {
    await _secure.write(key: _kSourceUrl, value: url);
    await Hive.box(_settingsBox).put('logged_in', true);
  }

  /// Get the saved source URL (used by the refresh button)
  static Future<String?> getSourceUrl() async {
    return _secure.read(key: _kSourceUrl);
  }

  /// Clear saved credentials (logout)
  static Future<void> clearCredentials() async {
    await _secure.deleteAll();
    await Hive.box(_settingsBox).delete('logged_in');
  }

  /// Check if user is logged in (synchronous, uses non-sensitive Hive flag)
  static bool isLoggedIn() {
    return Hive.box(_settingsBox).get('logged_in', defaultValue: false) == true;
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
    await clearCredentials();
  }
}
