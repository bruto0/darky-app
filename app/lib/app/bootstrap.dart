import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/browser/browser_profile.dart';
import '../core/browser/chrome_version.dart';
import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/storage/json_cache.dart';
import '../core/ui/theme_controller.dart';
import 'app.dart';
import 'providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');

  final config = AppConfig.defaults;
  final prefs = await SharedPreferences.getInstance();
  final chromeProvider = PlatformChromeVersionProvider(
    fallbackMajor: config.defaultChromeMajor,
  );
  final chrome = await chromeProvider.detect();
  AppLogger.instance.d(
    'Browser profile: Chrome ${chrome.major} (${chrome.sourceLabel})',
  );
  if (kDebugMode) {
    debugPrint(
      'DARKY browser: Chrome ${chrome.major} (${chrome.sourceLabel})',
    );
  }
  final profile = BrowserProfile.create(
    chromeMajor: chrome.major,
    config: config,
    locales: PlatformDispatcher.instance.locales,
  );

  JsonCache cache;
  try {
    cache = await JsonCache.create();
  } catch (_) {
    cache = JsonCache(Directory.systemTemp);
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        chromeVersionProvider.overrideWithValue(chromeProvider),
        browserProfileProvider.overrideWithValue(profile),
        sharedPreferencesProvider.overrideWithValue(prefs),
        jsonCacheProvider.overrideWithValue(cache),
      ],
      child: const DarkyApp(),
    ),
  );
}
