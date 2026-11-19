import 'package:dance/core/ui/theme.dart';
import 'package:dance/core/ui/theme_controller.dart';
import 'package:dance/features/account/theme_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pumpHarness(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showThemeDialog(context),
                child: const Text('Открыть темы'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Открыть темы'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('theme dialog shows all four designed options', (tester) async {
    await _pumpHarness(tester);

    expect(find.text('Тема оформления'), findsOneWidget);
    expect(find.text('Оформление применится сразу'), findsOneWidget);
    for (final mode in AppThemeMode.values) {
      expect(find.text(mode.label), findsOneWidget);
    }
    expect(find.text('Свет'), findsNothing);
    expect(find.text('Графит'), findsOneWidget);
    expect(find.text('Бренд'), findsOneWidget);
    expect(find.text('Авто'), findsOneWidget);
    expect(find.text('Готово'), findsOneWidget);
  });

  testWidgets('theme choice applies immediately and persists', (tester) async {
    final container = await _pumpHarness(tester);

    expect(find.byKey(const ValueKey('theme-check-light')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-check-dark')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('theme-card-dark')));
    await tester.pumpAndSettle();

    expect(container.read(themeControllerProvider), AppThemeMode.dark);
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(find.byKey(const ValueKey('theme-check-dark')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-check-light')), findsNothing);

    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
    expect(find.text('Тема оформления'), findsNothing);
  });

  testWidgets('stored theme marks the matching card on cold open', (
    tester,
  ) async {
    await _pumpHarness(tester, stored: {'theme_mode': 'pink'});

    expect(find.byKey(const ValueKey('theme-check-pink')), findsOneWidget);
    expect(find.byKey(const ValueKey('theme-check-light')), findsNothing);
  });
}
