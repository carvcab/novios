import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:novios/main.dart';
import 'package:novios/services/local_storage.dart';
import 'package:novios/services/theme_provider.dart';
import 'package:novios/services/chat_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    ChatNotificationService.isTesting = true;
    SharedPreferences.setMockInitialValues({});
    await LocalStorage().init();
    // Do not call firebase.init() to avoid platform channel mocking issues,
    // just set it manually or mock it if needed.
  });

  testWidgets('App launches and renders onboarding or lock screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const EverUsApp(),
      ),
    );

    // Let the animations and delay settle
    await tester.pump(const Duration(seconds: 2));

    // Verify it doesn't crash and renders MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
