import 'package:dio/dio.dart';
import '../models/channel.dart';
import 'm3u_parser.dart';
import 'storage_service.dart';

/// Service for managing playlist loading and caching
class PlaylistService {
  final Dio _dio;

  PlaylistService() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Load channels from a URL
  Future<List<Channel>> loadFromUrl(String url) async {
    try {
      final response = await _dio.get(url);
      final content = response.data as String;

      if (!M3UParser.isValidM3U(content)) {
        throw Exception('Invalid M3U format');
      }

      final channels = M3UParser.parse(content);

      // Cache channels locally
      await StorageService.saveChannels(channels);

      return channels;
    } catch (e) {
      // Try to load from cache if network fails
      final cached = StorageService.loadChannels();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Load channels from file content (when user picks a local file)
  List<Channel> loadFromContent(String content) {
    if (!M3UParser.isValidM3U(content)) {
      throw Exception('Invalid M3U format');
    }

    final channels = M3UParser.parse(content);
    StorageService.saveChannels(channels);
    return channels;
  }

  /// Load channels from cache
  List<Channel> loadFromCache() {
    return StorageService.loadChannels();
  }

  /// Get unique categories from channel list
  static List<String> getCategories(List<Channel> channels) {
    final categories = <String>{};
    for (final channel in channels) {
      if (channel.group != null && channel.group!.isNotEmpty) {
        categories.add(channel.group!);
      }
    }
    final sorted = categories.toList()..sort();
    return ['All', ...sorted];
  }

  /// Filter channels by category
  static List<Channel> filterByCategory(List<Channel> channels, String category) {
    if (category == 'All') return channels;
    return channels.where((c) => c.group == category).toList();
  }

  /// Search channels by name
  static List<Channel> search(List<Channel> channels, String query) {
    if (query.isEmpty) return channels;
    final lower = query.toLowerCase();
    return channels.where((c) =>
      c.name.toLowerCase().contains(lower) ||
      (c.group?.toLowerCase().contains(lower) ?? false)
    ).toList();
  }
}
