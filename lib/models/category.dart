/// Model representing a channel category/group
class Category {
  final String name;
  final int channelCount;
  final String? icon;

  const Category({
    required this.name,
    required this.channelCount,
    this.icon,
  });

  /// Default category icons based on common group names
  static String getIconForCategory(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('sport')) return '⚽';
    if (lower.contains('movie') || lower.contains('cine')) return '🎬';
    if (lower.contains('news') || lower.contains('noticias')) return '📰';
    if (lower.contains('music') || lower.contains('musica')) return '🎵';
    if (lower.contains('kids') || lower.contains('infantil')) return '🧸';
    if (lower.contains('documentary') || lower.contains('documental')) return '🌍';
    if (lower.contains('entertainment') || lower.contains('entretenimiento')) return '🎭';
    if (lower.contains('education') || lower.contains('educacion')) return '📚';
    if (lower.contains('religion')) return '⛪';
    if (lower.contains('cook') || lower.contains('cocina')) return '🍳';
    if (lower.contains('travel') || lower.contains('viaje')) return '✈️';
    if (lower.contains('science') || lower.contains('ciencia')) return '🔬';
    if (lower.contains('adult') || lower.contains('xxx')) return '🔞';
    return '📺';
  }
}
