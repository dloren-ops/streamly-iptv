/// Model representing a single EPG (Electronic Program Guide) program
class EpgProgram {
  final String channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime stop;

  const EpgProgram({
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.stop,
  });

  /// Whether this program is airing right now
  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(stop);
  }

  /// Progress (0.0 - 1.0) of the program if airing now
  double get progress {
    if (!isNow) return 0.0;
    final total = stop.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Formatted time range, e.g. "20:00 - 21:30"
  String get timeRange {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)} - '
        '${two(stop.hour)}:${two(stop.minute)}';
  }

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'title': title,
        'description': description,
        'start': start.toIso8601String(),
        'stop': stop.toIso8601String(),
      };

  factory EpgProgram.fromJson(Map<String, dynamic> json) => EpgProgram(
        channelId: json['channelId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        start: DateTime.parse(json['start']),
        stop: DateTime.parse(json['stop']),
      );
}
