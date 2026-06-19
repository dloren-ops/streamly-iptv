/// Type of on-demand content
enum VodType { movie, series }

/// Model representing a VOD item (movie or series) from Xtream API
class VodItem {
  final String id;
  final String name;
  final String? poster;
  final String? categoryId;
  final VodType type;
  final String? containerExtension;
  final double? rating;
  final String? plot;
  final String? genre;
  final String? year;

  const VodItem({
    required this.id,
    required this.name,
    required this.type,
    this.poster,
    this.categoryId,
    this.containerExtension,
    this.rating,
    this.plot,
    this.genre,
    this.year,
  });

  /// Parse a movie from get_vod_streams response
  factory VodItem.fromMovieJson(Map<String, dynamic> json) {
    return VodItem(
      id: json['stream_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      poster: json['stream_icon']?.toString(),
      categoryId: json['category_id']?.toString(),
      type: VodType.movie,
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      rating: double.tryParse(json['rating']?.toString() ?? ''),
      year: json['year']?.toString(),
    );
  }

  /// Parse a series from get_series response
  factory VodItem.fromSeriesJson(Map<String, dynamic> json) {
    return VodItem(
      id: json['series_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      poster: json['cover']?.toString(),
      categoryId: json['category_id']?.toString(),
      type: VodType.series,
      rating: double.tryParse(json['rating']?.toString() ?? ''),
      plot: json['plot']?.toString(),
      genre: json['genre']?.toString(),
      year: json['releaseDate']?.toString(),
    );
  }
}

/// A VOD category (group of movies or series)
class VodCategory {
  final String id;
  final String name;

  const VodCategory({required this.id, required this.name});

  factory VodCategory.fromJson(Map<String, dynamic> json) => VodCategory(
        id: json['category_id']?.toString() ?? '',
        name: json['category_name']?.toString() ?? 'Unknown',
      );
}

/// A single episode within a series
class Episode {
  final String id;
  final String title;
  final int season;
  final int episodeNum;
  final String? containerExtension;
  final String? plot;

  const Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.episodeNum,
    this.containerExtension,
    this.plot,
  });

  factory Episode.fromJson(Map<String, dynamic> json, int season) {
    final info = json['info'] is Map ? json['info'] as Map : const {};
    return Episode(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Episode ${json['episode_num']}',
      season: season,
      episodeNum: int.tryParse(json['episode_num']?.toString() ?? '0') ?? 0,
      containerExtension: json['container_extension']?.toString() ?? 'mp4',
      plot: info['plot']?.toString(),
    );
  }
}
