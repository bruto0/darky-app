import 'package:dance/app/providers.dart';
import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/core/ui/theme_controller.dart';
import 'package:dance/features/schedule/schedule_card.dart';
import 'package:dance/features/schedule/schedule_fab.dart';
import 'package:dance/features/schedule/schedule_page.dart';
import 'package:dance/features/schedule/schedule_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

void main() {
  testWidgets('SchedulePage is one scroll with the schedule and the FAB',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          branchClockProvider.overrideWithValue(fixedClock()),
          scheduleDayProvider.overrideWith((ref, day) async {
            return [
              for (var index = 0; index < 30; index++)
                scheduleItem(
                  id: '$index',
                  type: index.isEven ? 0 : 1,
                  clientId: 999,
                  clientName: 'Клиент',
                  hallName: 'Большой зал',
                  minutesBegin: 540 + index * 30,
                  minutesEnd: 570 + index * 30,
                ),
            ];
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SchedulePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleSection), findsOneWidget);
    expect(find.byType(ScheduleFab), findsOneWidget);
    expect(find.byType(Scrollable), findsOneWidget);
    // The last of 30 lessons is reachable by scrolling; no nested list.
    expect(find.byType(ScheduleCard), findsWidgets);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
