import 'package:dio/dio.dart';
import 'package:xml/xml_events.dart';
import '../models/epg_program.dart';

/// Service for loading and parsing EPG (XMLTV) data.
///
/// Uses an event-based (streaming) XML parser so large guides don't blow up
/// memory. Only keeps programs that are currently airing or upcoming.
class EpgService {
  final Dio _dio;

  EpgService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
        ));

  /// In-memory guide: epgChannelId -> ordered list of programs
  final Map<String, List<EpgProgram>> _guide = {};

  Map<String, List<EpgProgram>> get guide => _guide;

  /// Build the XMLTV EPG URL from Xtream credentials
  static String buildEpgUrl({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    var base = serverUrl.trim();
    if (!base.startsWith('http')) base = 'http://$base';
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return '$base/xmltv.php?username=$username&password=$password';
  }

  /// Load and parse EPG from a URL
  Future<void> loadFromUrl(String url) async {
    final response = await _dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    final content = response.data;
    if (content == null || content.isEmpty) return;
    parse(content);
  }

  /// Parse XMLTV content using a streaming event parser.
  void parse(String content) {
    _guide.clear();
    final now = DateTime.now();
    // Keep programs that haven't ended yet (plus a small grace period)
    final cutoff = now.subtract(const Duration(hours: 1));

    String? currentChannel;
    DateTime? start;
    DateTime? stop;
    String? title;
    String? desc;
    String? currentTag;

    for (final event in parseEvents(content)) {
      if (event is XmlStartElementEvent) {
        if (event.name == 'programme') {
          currentChannel = _attr(event, 'channel');
          start = _parseXmltvTime(_attr(event, 'start'));
          stop = _parseXmltvTime(_attr(event, 'stop'));
          title = null;
          desc = null;
        }
        currentTag = event.name;
      } else if (event is XmlTextEvent) {
        if (currentTag == 'title') {
          title = (title ?? '') + event.value;
        } else if (currentTag == 'desc') {
          desc = (desc ?? '') + event.value;
        }
      } else if (event is XmlEndElementEvent) {
        if (event.name == 'programme' &&
            currentChannel != null &&
            start != null &&
            stop != null) {
          // Only keep current/future programs to stay lightweight
          if (stop.isAfter(cutoff)) {
            final program = EpgProgram(
              channelId: currentChannel,
              title: (title ?? 'No info').trim(),
              description: desc?.trim(),
              start: start,
              stop: stop,
            );
            _guide.putIfAbsent(currentChannel, () => []).add(program);
          }
          currentChannel = null;
          start = null;
          stop = null;
        }
        currentTag = null;
      }
    }

    // Sort each channel's programs by start time
    for (final list in _guide.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
  }

  /// Get the program currently airing on a channel
  EpgProgram? getCurrentProgram(String? epgChannelId) {
    if (epgChannelId == null) return null;
    final programs = _guide[epgChannelId];
    if (programs == null) return null;
    for (final p in programs) {
      if (p.isNow) return p;
    }
    return null;
  }

  /// Get the next upcoming program on a channel
  EpgProgram? getNextProgram(String? epgChannelId) {
    if (epgChannelId == null) return null;
    final programs = _guide[epgChannelId];
    if (programs == null) return null;
    final now = DateTime.now();
    for (final p in programs) {
      if (p.start.isAfter(now)) return p;
    }
    return null;
  }

  /// Get the full upcoming schedule for a channel
  List<EpgProgram> getSchedule(String? epgChannelId) {
    if (epgChannelId == null) return [];
    return _guide[epgChannelId] ?? [];
  }

  bool get hasData => _guide.isNotEmpty;

  // ─── Helpers ────────────────────────────────────────────────

  String? _attr(XmlStartElementEvent event, String name) {
    for (final a in event.attributes) {
      if (a.name == name) return a.value;
    }
    return null;
  }

  /// Parse XMLTV time format: "20231201200000 +0000"
  DateTime? _parseXmltvTime(String? raw) {
    if (raw == null || raw.length < 14) return null;
    try {
      final year = int.parse(raw.substring(0, 4));
      final month = int.parse(raw.substring(4, 6));
      final day = int.parse(raw.substring(6, 8));
      final hour = int.parse(raw.substring(8, 10));
      final minute = int.parse(raw.substring(10, 12));
      final second = int.parse(raw.substring(12, 14));

      var dt = DateTime.utc(year, month, day, hour, minute, second);

      // Apply timezone offset if present, e.g. "+0000" or "-0500"
      final tzPart = raw.substring(14).trim();
      if (tzPart.length >= 5) {
        final sign = tzPart[0] == '-' ? 1 : -1; // convert to UTC
        final offHour = int.parse(tzPart.substring(1, 3));
        final offMin = int.parse(tzPart.substring(3, 5));
        dt = dt.add(Duration(hours: sign * offHour, minutes: sign * offMin));
      }
      return dt.toLocal();
    } catch (_) {
      return null;
    }
  }
}
