import 'package:flutter_test/flutter_test.dart';
import 'package:streamly_iptv/services/m3u_parser.dart';
import 'package:streamly_iptv/services/xtream_service.dart';

void main() {
  group('M3UParser', () {
    test('parses a basic channel with attributes', () {
      const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="ch1" tvg-logo="http://logo.png" group-title="Sports",ESPN
http://example.com/stream1
''';
      final channels = M3UParser.parse(content);

      expect(channels.length, 1);
      expect(channels.first.name, 'ESPN');
      expect(channels.first.url, 'http://example.com/stream1');
      expect(channels.first.group, 'Sports');
      expect(channels.first.logo, 'http://logo.png');
      expect(channels.first.epgChannelId, 'ch1');
    });

    test('parses multiple channels', () {
      const content = '''
#EXTM3U
#EXTINF:-1,Channel One
http://example.com/1
#EXTINF:-1,Channel Two
http://example.com/2
''';
      final channels = M3UParser.parse(content);
      expect(channels.length, 2);
      expect(channels[1].name, 'Channel Two');
    });

    test('detects valid and invalid M3U content', () {
      expect(M3UParser.isValidM3U('#EXTM3U\n'), isTrue);
      expect(M3UParser.isValidM3U('just some text'), isFalse);
    });
  });

  group('XtreamService', () {
    test('normalizes URLs (adds scheme, trims trailing slash)', () {
      expect(XtreamService.normalizeUrl('server.com:8080/'),
          'http://server.com:8080');
      expect(XtreamService.normalizeUrl('https://server.com'),
          'https://server.com');
    });

    test('builds the M3U URL from credentials', () {
      final url = XtreamService.buildM3UUrl(
        serverUrl: 'http://server.com:8080',
        username: 'user',
        password: 'pass',
      );
      expect(url,
          'http://server.com:8080/get.php?username=user&password=pass&type=m3u_plus&output=ts');
    });
  });
}
