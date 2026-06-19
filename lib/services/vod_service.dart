import 'package:dio/dio.dart';
import '../models/vod_item.dart';
import 'xtream_service.dart';

/// Service for fetching Video On Demand (movies & series) from Xtream API
class VodService {
  final Dio _dio;

  VodService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ));

  String _base(String serverUrl) => XtreamService.normalizeUrl(serverUrl);

  String _api({
    required String serverUrl,
    required String username,
    required String password,
    required String action,
    Map<String, String>? extra,
  }) {
    final params = StringBuffer(
      '${_base(serverUrl)}/player_api.php?username=$username&password=$password&action=$action',
    );
    extra?.forEach((k, v) => params.write('&$k=$v'));
    return params.toString();
  }

  Future<List<dynamic>> _getList(String url) async {
    final response = await _dio.get(url);
    final data = response.data;
    if (data is List) return data;
    return const [];
  }

  // ─── Movies ─────────────────────────────────────────────────

  Future<List<VodCategory>> getMovieCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = _api(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: 'get_vod_categories',
    );
    final list = await _getList(url);
    return list
        .map((e) => VodCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<VodItem>> getMovies({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final url = _api(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: 'get_vod_streams',
      extra: categoryId != null ? {'category_id': categoryId} : null,
    );
    final list = await _getList(url);
    return list
        .map((e) => VodItem.fromMovieJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Build the playable URL for a movie
  static String buildMovieUrl({
    required String serverUrl,
    required String username,
    required String password,
    required VodItem movie,
  }) {
    final base = XtreamService.normalizeUrl(serverUrl);
    final ext = movie.containerExtension ?? 'mp4';
    return '$base/movie/$username/$password/${movie.id}.$ext';
  }

  // ─── Series ─────────────────────────────────────────────────

  Future<List<VodCategory>> getSeriesCategories({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final url = _api(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: 'get_series_categories',
    );
    final list = await _getList(url);
    return list
        .map((e) => VodCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<VodItem>> getSeries({
    required String serverUrl,
    required String username,
    required String password,
    String? categoryId,
  }) async {
    final url = _api(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: 'get_series',
      extra: categoryId != null ? {'category_id': categoryId} : null,
    );
    final list = await _getList(url);
    return list
        .map((e) => VodItem.fromSeriesJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get episodes of a series, grouped by season number
  Future<Map<int, List<Episode>>> getSeriesEpisodes({
    required String serverUrl,
    required String username,
    required String password,
    required String seriesId,
  }) async {
    final url = _api(
      serverUrl: serverUrl,
      username: username,
      password: password,
      action: 'get_series_info',
      extra: {'series_id': seriesId},
    );
    final response = await _dio.get(url);
    final data = response.data;
    final result = <int, List<Episode>>{};

    if (data is Map && data['episodes'] is Map) {
      final episodes = data['episodes'] as Map;
      episodes.forEach((seasonKey, episodeList) {
        final season = int.tryParse(seasonKey.toString()) ?? 0;
        if (episodeList is List) {
          result[season] = episodeList
              .map((e) => Episode.fromJson(Map<String, dynamic>.from(e), season))
              .toList();
        }
      });
    }
    return result;
  }

  /// Build the playable URL for a series episode
  static String buildEpisodeUrl({
    required String serverUrl,
    required String username,
    required String password,
    required Episode episode,
  }) {
    final base = XtreamService.normalizeUrl(serverUrl);
    final ext = episode.containerExtension ?? 'mp4';
    return '$base/series/$username/$password/${episode.id}.$ext';
  }
}
