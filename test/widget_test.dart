// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:streamly_iptv/providers/channel_provider.dart';
import 'package:streamly_iptv/providers/vod_provider.dart';
import 'package:streamly_iptv/screens/login_screen.dart';

void main() {
  testWidgets('App smoke test - LoginScreen renders', (WidgetTester tester) async {
    // Pump LoginScreen directly inside a MaterialApp with required providers,
    // bypassing StorageService.isLoggedIn() which needs Hive initialization.
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

    // Verify that the app builds without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
