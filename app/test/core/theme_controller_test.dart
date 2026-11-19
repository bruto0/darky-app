import 'package:dance/core/ui/theme.dart';
import 'package:dance/core/ui/theme_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restores and persists the selected theme', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'pink'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider), AppThemeMode.pink);
    container
        .read(themeControllerProvider.notifier)
        .setMode(AppThemeMode.dark);
    expect(container.read(themeControllerProvider), AppThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('falls back to light for an unknown stored value', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'unknown'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeControllerProvider), AppThemeMode.light);
  });
}
