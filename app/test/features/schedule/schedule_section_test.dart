import 'dart:async';

import 'package:dance/app/providers.dart';
import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/models/schedule_item.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/schedule/schedule_card.dart';
import 'package:dance/features/schedule/schedule_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget harness(List<Override> overrides, {double? textScale}) {
    return ProviderScope(
      overrides: [
        branchClockProvider.overrideWithValue(fixedClock()),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: textScale == null
            ? null
            : (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: child!,
                ),
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [ScheduleSection()],
          ),
        ),
      ),
    );
  }

  testWidgets('renders header, filters, week strip and full day list',
      (tester) async {
    useTallPhone(tester);
    final items = [
      scheduleItem(
        id: '1',
        type: 0,
        title: 'Бачата',
        hallName: 'Большой зал',
        minutesBegin: 600,
        minutesEnd: 660,
      ),
      scheduleItem(
        id: '2',
        type: 1,
        clientId: 999,
        clientName: 'Пётр Петров',
        hallName: 'Средний зал',
        minutesBegin: 660,
        minutesEnd: 720,
      ),
      scheduleItem(
        id: '3',
        type: 1,
        isMine: true,
        clientName: 'Анна Смирнова',
        teacherName: 'Андрей Чистяков',
        hallName: 'Средний зал',
        minutesBegin: 720,
        minutesEnd: 780,
      ),
      scheduleItem(
        id: '4',
        type: 2,
        clientId: 999,
        clientName: 'Пётр Петров',
        hallName: 'Большой зал',
        minutesBegin: 780,
        minutesEnd: 840,
      ),
    ];

    await tester.pumpWidget(
      harness([
        scheduleDayProvider.overrideWith((ref, day) async => items),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Расписание'), findsOneWidget);
    expect(find.text('Сегодня, 19 ноября'), findsOneWidget);
    expect(find.text('Зал · Все'), findsOneWidget);
    expect(find.text('Преподаватель · Все'), findsOneWidget);
    for (final weekday in ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']) {
      expect(find.text(weekday), findsOneWidget);
    }
    expect(find.text('19'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsNWidgets(4));

    // Exactly one Scrollable: the parent CustomScrollView. No nested list.
    expect(find.byType(Scrollable), findsOneWidget);

    // Privacy: the foreign individual exposes only "индив" and the hall;
    // type 2 rent now intentionally shows the tenant name.
    expect(find.text('индив'), findsOneWidget);
    expect(find.text('аренда Пётр Петров'), findsOneWidget);
  });

  testWidgets('loading keeps week and filters, then shows empty state',
      (tester) async {
    useTallPhone(tester);
    final completer = Completer<List<ScheduleItem>>();

    await tester.pumpWidget(
      harness([
        scheduleDayProvider.overrideWith((ref, day) => completer.future),
      ]),
    );
    await tester.pump();

    expect(find.text('Расписание'), findsOneWidget);
    expect(find.text('Зал · Все'), findsOneWidget);
    expect(find.text('ПН'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsNothing);

    completer.complete(const <ScheduleItem>[]);
    await tester.pumpAndSettle();

    expect(find.text('На этот день занятий нет'), findsOneWidget);
    expect(find.text('Выбрать другой день'), findsOneWidget);
    expect(find.text('ПН'), findsOneWidget);
  });

  testWidgets('error keeps week and filters, retry reloads the day',
      (tester) async {
    useTallPhone(tester);
    var calls = 0;

    await tester.pumpWidget(
      harness([
        scheduleDayProvider.overrideWith((ref, day) async {
          calls++;
          if (calls == 1) throw const NetworkFailure();
          return [
            scheduleItem(
              id: '1',
              hallName: 'Малый зал',
              minutesBegin: 600,
              minutesEnd: 660,
            ),
          ];
        }),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Расписание не загрузилось'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('ПН'), findsOneWidget);
    expect(find.text('Зал · Все'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('Расписание не загрузилось'), findsNothing);
    expect(find.byType(ScheduleCard), findsOneWidget);
  });

  testWidgets('hall and teacher filters apply client-side, persist across days',
      (tester) async {
    useTallPhone(tester);
    final items = [
      scheduleItem(
        id: '1',
        hallName: 'Зал 1',
        teacherName: 'Мария',
        minutesBegin: 600,
        minutesEnd: 660,
      ),
      scheduleItem(
        id: '2',
        hallName: 'Зал 2',
        teacherName: 'Олег',
        minutesBegin: 660,
        minutesEnd: 720,
      ),
      scheduleItem(
        id: '3',
        hallName: 'Зал 1',
        teacherName: 'Олег',
        minutesBegin: 720,
        minutesEnd: 780,
      ),
    ];

    await tester.pumpWidget(
      harness([
        scheduleDayProvider.overrideWith((ref, day) async => items),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleCard), findsNWidgets(3));

    // Hall filter.
    await tester.tap(find.text('Зал · Все'));
    await tester.pumpAndSettle();
    expect(find.text('Зал 2'), findsWidgets);
    await tester.tap(find.widgetWithText(InkWell, 'Зал 1').last);
    await tester.pumpAndSettle();

    expect(find.text('Зал · Зал 1'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsNWidgets(2));

    // Teacher filter combines with the hall filter (no Apply button).
    await tester.tap(find.text('Преподаватель · Все'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Олег').last);
    await tester.pumpAndSettle();

    expect(find.text('Преподаватель · Олег'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsOneWidget);

    // Switching to the next week keeps both filters.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('26 ноября'), findsOneWidget);
    expect(find.text('Зал · Зал 1'), findsOneWidget);
    expect(find.text('Преподаватель · Олег'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsOneWidget);

    // "Все" resets only its own filter.
    await tester.tap(find.text('Зал · Зал 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Все').last);
    await tester.pumpAndSettle();
    expect(find.text('Зал · Все'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsNWidgets(2));

    await tester.tap(find.text('Преподаватель · Олег'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Все').last);
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleCard), findsNWidgets(3));
  });

  testWidgets('horizontal swipe moves the week without resetting filters',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      harness([
        scheduleDayProvider.overrideWith(
          (ref, day) async => [scheduleItem(id: '1')],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Зал · Все'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Большой зал').last);
    await tester.pumpAndSettle();
    expect(find.text('Зал · Большой зал'), findsOneWidget);

    await tester.fling(find.text('ПН'), const Offset(-300, 0), 1200);
    await tester.pumpAndSettle();

    expect(find.text('26 ноября'), findsOneWidget);
    expect(find.text('Зал · Большой зал'), findsOneWidget);
  });

  testWidgets('filter options come from the unfiltered day, filtered empty resets',
      (tester) async {
    useTallPhone(tester);
    final items = [
      scheduleItem(
        id: '1',
        hallName: 'Зал 1',
        teacherName: 'Мария',
        minutesBegin: 600,
        minutesEnd: 660,
      ),
      scheduleItem(
        id: '2',
        hallName: 'Зал 2',
        teacherName: 'Олег',
        minutesBegin: 660,
        minutesEnd: 720,
      ),
    ];

    await tester.pumpWidget(
      harness([
        scheduleDayProvider.overrideWith((ref, day) async => items),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Зал · Все'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Зал 2').last);
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleCard), findsOneWidget);

    // "Мария" is absent from the filtered view but still offered, because the
    // options are derived from the loaded unfiltered day.
    await tester.tap(find.text('Преподаватель · Все'));
    await tester.pumpAndSettle();
    expect(find.text('Мария'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, 'Мария').last);
    await tester.pumpAndSettle();

    expect(find.text('Нет занятий с выбранными фильтрами'), findsOneWidget);
    expect(find.text('Сбросить фильтры'), findsOneWidget);

    await tester.tap(find.text('Сбросить фильтры'));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleCard), findsNWidgets(2));
    expect(find.text('Зал · Все'), findsOneWidget);
    expect(find.text('Преподаватель · Все'), findsOneWidget);
  });

  testWidgets('empty state action stays inside the one parent scroll',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      harness([
        scheduleDayProvider.overrideWith(
          (ref, day) async => const <ScheduleItem>[],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Выбрать другой день'));
    await tester.pumpAndSettle();

    expect(find.text('На этот день занятий нет'), findsOneWidget);
    expect(find.byType(Scrollable), findsOneWidget);
  });

  testWidgets('fits 360 dp at 1.3 text scale without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = [
      scheduleItem(
        id: '1',
        type: 0,
        title: 'Очень длинное название группы',
        groupLevel: 'База 2.0',
        hallName: 'Большой зал',
        teacherName: 'Мария',
        stickerName: 'сампо',
        changeText: 'Очень Длинная Фамилия',
        minutesBegin: 600,
        minutesEnd: 660,
      ),
      scheduleItem(
        id: '2',
        type: 1,
        isMine: true,
        clientName: 'Анна Смирнова',
        teacherName: 'Андрей Чистяков',
        hallName: 'Средний зал',
        minutesBegin: 660,
        minutesEnd: 720,
      ),
      scheduleItem(
        id: '3',
        type: 2,
        clientId: 999,
        clientName: 'Пётр Петров',
        hallName: 'Очень длинное название зала',
        minutesBegin: 720,
        minutesEnd: 780,
      ),
    ];

    await tester.pumpWidget(
      harness(
        [
          scheduleDayProvider.overrideWith((ref, day) async => items),
        ],
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Расписание'), findsOneWidget);
    expect(find.text('Зал · Все'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsNWidgets(3));
  });
}
