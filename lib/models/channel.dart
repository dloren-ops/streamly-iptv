/// Model representing an IPTV channel
class Channel {
  final String id;
  final String name;
  final String url;
  final String? logo;
  final String? group;
  final String? language;
  final String? country;
  bool isFavorite;

  Channel({
    required this.id,
    required this.name,
    required this.url,
    this.logo,
    this.group,
    this.language,
    this.country,
    this.isFavorite = false,
  });

  /// Create a Channel from M3U parsed data
  factory Channel.fromM3UData({
    required String name,
    required String url,
    Map<String, String>? attributes,
  }) {
    return Channel(
      id: url.hashCode.toString(),
      name: name.trim(),
      url: url.trim(),
      logo: attributes?['tvg-logo'] ?? attributes?['logo'],
      group: attributes?['group-title'],
      language: attributes?['tvg-language'],
      country: attributes?['tvg-country'],
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
        'language': language,
        'country': country,
        'isFavorite': isFavorite,
      };

  /// Create from JSON (local storage)
  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        url: json['url'] ?? '',
        logo: json['logo'],
        group: json['group'],
        language: json['language'],
        country: json['country'],
        isFavorite: json['isFavorite'] ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Channel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
