import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:streamly_iptv/providers/channel_provider.dart';
import 'package:streamly_iptv/providers/vod_provider.dart';
import 'package:streamly_iptv/screens/login_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChannelProvider()),
          ChangeNotifierProvider(create: (_) => VodProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
