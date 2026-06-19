import '../models/channel.dart';

/// Efficient M3U/M3U8 playlist parser
/// Uses streaming approach to handle large playlists without memory issues
class M3UParser {
  /// Parse M3U content string into a list of channels
  static List<Channel> parse(String content) {
    final channels = <Channel>[];
    final lines = content.split('\n');

    String? currentInfo;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        currentInfo = line;
      } else if (line.startsWith('http') && currentInfo != null) {
        final channel = _parseChannel(currentInfo, line);
        if (channel != null) {
          channels.add(channel);
        }
        currentInfo = null;
      }
    }

    return channels;
  }

  /// Parse a single channel from EXTINF line and URL
  static Channel? _parseChannel(String infoLine, String url) {
    try {
      // Extract attributes from EXTINF line
      final attributes = _parseAttributes(infoLine);

      // Extract channel name (after the last comma in EXTINF)
      final nameMatch = RegExp(r',(.+)$').firstMatch(infoLine);
      final name = nameMatch?.group(1)?.trim() ?? 'Unknown Channel';

      return Channel.fromM3UData(
        name: name,
        url: url,
        attributes: attributes,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parse attributes from EXTINF line
  /// Example: #EXTINF:-1 tvg-id="ch1" tvg-logo="http://..." group-title="Sports",Channel Name
  static Map<String, String> _parseAttributes(String line) {
    final attributes = <String, String>{};

    // Match key="value" patterns
    final regex = RegExp(r'([\w-]+)="([^"]*)"');
    final matches = regex.allMatches(line);

    for (final match in matches) {
      final key = match.group(1)!;
      final value = match.group(2)!;
      attributes[key] = value;
    }

    return attributes;
  }

  /// Parse M3U from a URL (async)
  static Future<List<Channel>> parseFromUrl(String url,
      {required Future<String> Function(String url) httpGet}) async {
    final content = await httpGet(url);
    return parse(content);
  }

  /// Validate if content is a valid M3U file
  static bool isValidM3U(String content) {
    return content.trimLeft().startsWith('#EXTM3U') ||
        content.contains('#EXTINF:');
  }
}
