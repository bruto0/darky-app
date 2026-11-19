import 'dart:async';

import 'package:dance/app/providers.dart';
import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/models/schedule_item.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/core/ui/theme_controller.dart';
import 'package:dance/features/schedule/schedule_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScheduleFabGeometry', () {
    test('clamps fully into safe area including status bar and nav reserve', () {
      const geometry = ScheduleFabGeometry(
        parentSize: Size(390, 800),
        safePadding: EdgeInsets.only(top: 24, bottom: 34),
      );

      expect(geometry.minX, 16);
      expect(geometry.maxX, 322);
      expect(geometry.minY, 40);
      expect(geometry.maxY, 698);
      expect(geometry.defaultOffset, const Offset(322, 698));

      expect(geometry.clamp(const Offset(-100, -100)), const Offset(16, 40));
      expect(geometry.clamp(const Offset(1000, 1000)), const Offset(322, 698));
    });

    test('bottomReserve keeps the circle above a navigation bar', () {
      const geometry = ScheduleFabGeometry(
        parentSize: Size(390, 800),
        safePadding: EdgeInsets.zero,
        bottomReserve: 96,
      );

      expect(geometry.maxY, 800 - 96 - 16 - 52);
      expect(geometry.clamp(const Offset(0, 999)), const Offset(16, 636));
    });

    test('normalized position round-trips and resolves clamped', () {
      const geometry = ScheduleFabGeometry(
        parentSize: Size(390, 800),
        safePadding: EdgeInsets.only(top: 24, bottom: 34),
      );

      expect(geometry.resolve(Offset.zero), const Offset(16, 40));
      expect(geometry.resolve(const Offset(1, 1)), const Offset(322, 698));
      expect(geometry.resolve(const Offset(2, 2)), const Offset(322, 698));

      final normalized = geometry.normalize(const Offset(-100, -100));
      expect(normalized.dx, closeTo(0, 1e-9));
      expect(normalized.dy, closeTo(0, 1e-9));
      expect(geometry.resolve(normalized), const Offset(16, 40));
    });

    test('tiny parent never produces inverted bounds', () {
      const geometry = ScheduleFabGeometry(
        parentSize: Size(40, 40),
        safePadding: EdgeInsets.zero,
      );

      expect(geometry.minX, 16);
      expect(geometry.maxX, 16);
      expect(geometry.minY, 16);
      expect(geometry.maxY, 16);
      expect(geometry.clamp(const Offset(999, 999)), const Offset(16, 16));
    });
  });

  group('ScheduleFab widget', () {
    Future<Widget> harness(
      SharedPreferences prefs, {
      required Override scheduleOverride,
      double bottomReserve = 0,
    }) async {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          branchClockProvider.overrideWithValue(fixedClock()),
          scheduleOverride,
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: ScheduleFab(bottomReserve: bottomReserve),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('tap invalidates the selected day exactly once', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      var calls = 0;
      final widget = await harness(
        prefs,
        scheduleOverride: scheduleDayProvider.overrideWith((ref, day) async {
          calls++;
          return const <ScheduleItem>[];
        }),
      );

      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();
      expect(calls, 1);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byKey(ScheduleFab.buttonKey));
      await tester.pump();
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('shows a spinner while the day is loading', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final completer = Completer<List<ScheduleItem>>();
      final widget = await harness(
        prefs,
        scheduleOverride:
            scheduleDayProvider.overrideWith((ref, day) => completer.future),
      );

      await tester.pumpWidget(widget);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsNothing);

      completer.complete(const []);
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('drag clamps, persists and restores the normalized position',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final widget = await harness(
        prefs,
        scheduleOverride: scheduleDayProvider.overrideWith(
          (ref, day) async => const <ScheduleItem>[],
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();

      final start = tester.getTopLeft(find.byKey(ScheduleFab.buttonKey));
      expect(start.dx, closeTo(800 - 16 - 52, 0.1));
      expect(start.dy, closeTo(600 - 16 - 52, 0.1));

      await tester.drag(
        find.byKey(ScheduleFab.buttonKey),
        const Offset(-800, -600),
      );
      await tester.pump();

      final dragged = tester.getTopLeft(find.byKey(ScheduleFab.buttonKey));
      expect(dragged.dx, closeTo(16, 0.1));
      expect(dragged.dy, closeTo(16, 0.1));
      expect(prefs.getDouble('schedule_fab_x'), 0);
      expect(prefs.getDouble('schedule_fab_y'), 0);

      // Restart: a fresh widget tree reads the saved position.
      await tester.pumpWidget(const SizedBox.shrink());
      final restarted = await harness(
        prefs,
        scheduleOverride: scheduleDayProvider.overrideWith(
          (ref, day) async => const <ScheduleItem>[],
        ),
      );
      await tester.pumpWidget(restarted);
      await tester.pump();
      await tester.pump();

      final restored = tester.getTopLeft(find.byKey(ScheduleFab.buttonKey));
      expect(restored.dx, closeTo(16, 0.1));
      expect(restored.dy, closeTo(16, 0.1));
    });

    testWidgets('has a Russian semantic label', (tester) async {
      final handle = tester.ensureSemantics();
      final prefs = await SharedPreferences.getInstance();
      final widget = await harness(
        prefs,
        scheduleOverride: scheduleDayProvider.overrideWith(
          (ref, day) async => const <ScheduleItem>[],
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pump();
      await tester.pump();

      expect(find.bySemanticsLabel('Обновить расписание'), findsOneWidget);
      handle.dispose();
    });
  });
}
