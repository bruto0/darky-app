import 'dart:io';
import 'dart:ui' show Locale;

import 'package:dance/app/app.dart';
import 'package:dance/app/providers.dart';
import 'package:dance/core/browser/browser_profile.dart';
import 'package:dance/core/config/app_config.dart';
import 'package:dance/core/contracts/fakes.dart';
import 'package:dance/core/storage/json_cache.dart';
import 'package:dance/core/storage/session.dart';
import 'package:dance/core/ui/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shell shows four tabs and the home placeholder', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final config = AppConfig.defaults;
    final profile = BrowserProfile.create(
      chromeMajor: 156,
      config: config,
      locales: const [Locale('ru', 'RU')],
    );
    final session = Session(
      clientId: 255,
      secret: 'demo',
      profile: const ClientProfile(
        id: 255,
        firstName: 'Анна',
        lastName: 'Смирнова',
      ),
      createdAt: DateTime.utc(2026, 11, 19),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          sharedPreferencesProvider.overrideWithValue(prefs),
          browserProfileProvider.overrideWithValue(profile),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(session: session),
          ),
          jsonCacheProvider.overrideWithValue(
            JsonCache(Directory.systemTemp),
          ),
        ],
        child: const DarkyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Абонемент'), findsWidgets);
    expect(find.text('Посещения'), findsWidgets);
    expect(find.text('Покупки'), findsWidgets);
    expect(find.text('Записи'), findsWidgets);
  });
}
