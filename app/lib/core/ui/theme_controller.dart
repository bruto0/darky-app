import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at bootstrap');
});

final themeControllerProvider =
    NotifierProvider<ThemeController, AppThemeMode>(ThemeController.new);

class ThemeController extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode';

  @override
  AppThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppThemeMode.normalize(
      AppThemeMode.fromStorage(prefs.getString(_key)),
    );
  }

  void setMode(AppThemeMode mode) {
    final normalized = AppThemeMode.normalize(mode);
    if (state == normalized) return;
    state = normalized;
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setString(_key, normalized.storageValue));
  }
}
