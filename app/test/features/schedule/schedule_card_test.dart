import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/schedule/schedule_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'test_support.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  testWidgets('group card shows title, level, hall, sticker and red change',
      (tester) async {
    final item = scheduleItem(
      id: 'g1',
      type: 0,
      title: 'Бачата',
      styleName: 'Бачата',
      groupLevel: 'База 2.0',
      hallName: 'Большой зал',
      teacherName: 'Мария Иванова',
      mainTeacherNames: ['Мария Иванова', 'Наталья Губина'],
      substituteTeacherNames: ['Семьянов В. С.'],
      stickerName: 'сампо',
      changeText: 'Замена: Семьянов В. С.',
      minutesBegin: 840,
      minutesEnd: 900,
    );

    await tester.pumpWidget(testApp(ScheduleCard(item: item, clock: fixedClock())));

    expect(find.text('Бачата База 2.0'), findsOneWidget);
    expect(find.text('Большой зал'), findsOneWidget);
    expect(find.text('САМПО'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('60 мин'), findsOneWidget);

    expect(find.text('Мария Иванова, Наталья Губина'), findsOneWidget);
    final change = tester.widget<Text>(find.text('Замена: Семьянов В. С.'));
    expect(change.style?.color, AppPalette.light.red);
  });

  testWidgets('group card shows only main teachers without a substitution',
      (tester) async {
    final item = scheduleItem(
      id: 'g2',
      type: 0,
      title: 'Бачата',
      styleName: 'Бачата',
      hallName: 'Большой зал',
      mainTeacherNames: ['Мария Иванова', 'Наталья Губина'],
      minutesBegin: 840,
      minutesEnd: 900,
    );

    await tester.pumpWidget(testApp(ScheduleCard(item: item, clock: fixedClock())));

    expect(find.text('Мария Иванова, Наталья Губина'), findsOneWidget);
    expect(find.textContaining('Замена'), findsNothing);
  });

  testWidgets('own individual card shows client, teacher, hall and violet rail',
      (tester) async {
    final item = scheduleItem(
      id: 'i1',
      type: 1,
      clientId: 255,
      clientName: 'Анна Смирнова',
      teacherName: 'Андрей Чистяков',
      hallName: 'Средний зал',
      minutesBegin: 720,
      minutesEnd: 780,
    );

    await tester.pumpWidget(
      testApp(ScheduleCard(item: item, clock: fixedClock(), clientId: 255)),
    );

    expect(find.text('Анна Смирнова'), findsOneWidget);
    expect(find.text('Андрей Чистяков'), findsOneWidget);
    expect(find.text('Средний зал'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(
      scheduleRailColor(item, AppPalette.light, isOwn: true),
      AppPalette.light.violet,
    );
  });

  testWidgets('own individual is detected by clientId even without isMine',
      (tester) async {
    final item = scheduleItem(
      id: 'i2',
      type: 1,
      clientId: 255,
      clientName: 'Анна Смирнова',
      teacherName: 'Андрей Чистяков',
      hallName: 'Средний зал',
      minutesBegin: 720,
      minutesEnd: 780,
    );

    await tester.pumpWidget(
      testApp(ScheduleCard(item: item, clock: fixedClock(), clientId: 255)),
    );

    expect(isOwnScheduleItem(item, 255), isTrue);
    expect(find.text('Анна Смирнова'), findsOneWidget);
    expect(find.text('Андрей Чистяков'), findsOneWidget);
  });

  testWidgets('own individual without teacher does not crash or show a teacher',
      (tester) async {
    final item = scheduleItem(
      id: 'i3',
      type: 1,
      isMine: true,
      clientName: 'Анна Смирнова',
      hallName: 'Малый зал',
      minutesBegin: 720,
      minutesEnd: 780,
    );

    await tester.pumpWidget(testApp(ScheduleCard(item: item, clock: fixedClock())));

    expect(find.text('Анна Смирнова'), findsOneWidget);
    expect(find.text('Малый зал'), findsOneWidget);
    expect(find.byType(ScheduleCard), findsOneWidget);
  });

  testWidgets('foreign individual leaks no name, teacher, style or sticker',
      (tester) async {
    final item = scheduleItem(
      id: 'i4',
      type: 1,
      clientId: 999,
      clientName: 'Пётр Петров',
      teacherName: 'Секретный Преподаватель',
      styleName: 'Приватная Бачата',
      hallName: 'Малый зал',
      stickerName: 'сампо',
      changeText: 'Замена: Скрытый Учитель',
      typeTitle: 'Индивидуальное занятие',
      minutesBegin: 780,
      minutesEnd: 840,
    );

    await tester.pumpWidget(
      testApp(ScheduleCard(item: item, clock: fixedClock(), clientId: 255)),
    );

    expect(find.text('индив'), findsOneWidget);
    expect(find.text('Малый зал'), findsOneWidget);
    expect(find.text('13:00'), findsOneWidget);
    expect(find.textContaining('Пётр'), findsNothing);
    expect(find.textContaining('Секретный'), findsNothing);
    expect(find.textContaining('Приватная'), findsNothing);
    expect(find.textContaining('САМПО'), findsNothing);
    expect(find.textContaining('Замена'), findsNothing);
    expect(find.textContaining('Индивидуальное'), findsNothing);
    expect(isOwnScheduleItem(item, 255), isFalse);
  });

  testWidgets('own rent shows tenant name, prefix and hall last', (tester) async {
    final item = scheduleItem(
      id: 'r1',
      type: 2,
      isMine: true,
      clientName: 'Анна Смирнова',
      hallName: 'Большой зал',
      minutesBegin: 900,
      minutesEnd: 960,
    );

    await tester.pumpWidget(testApp(ScheduleCard(item: item, clock: fixedClock())));

    expect(find.text('аренда Анна Смирнова'), findsOneWidget);
    expect(find.text('Большой зал'), findsOneWidget);
    expect(find.text('15:00'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Большой зал')).dy,
      greaterThan(tester.getTopLeft(find.text('аренда Анна Смирнова')).dy),
    );
  });

  testWidgets('foreign rent shows tenant name without teacher', (tester) async {
    final item = scheduleItem(
      id: 'r2',
      type: 2,
      clientId: 999,
      clientName: 'Пётр Петров',
      teacherName: 'Секретный Преподаватель',
      hallName: 'Большой зал',
      minutesBegin: 900,
      minutesEnd: 960,
    );

    await tester.pumpWidget(
      testApp(ScheduleCard(item: item, clock: fixedClock(), clientId: 255)),
    );

    expect(find.text('аренда Пётр Петров'), findsOneWidget);
    expect(find.text('Большой зал'), findsOneWidget);
    expect(find.textContaining('Секретный'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Большой зал')).dy,
      greaterThan(tester.getTopLeft(find.text('аренда Пётр Петров')).dy),
    );
  });

  testWidgets('sampo rent replaces the first word and keeps hall last',
      (tester) async {
    final item = scheduleItem(
      id: 'r3',
      type: 2,
      clientId: 999,
      clientName: 'Пётр Петров',
      stickerName: 'сАмПо',
      hallName: 'Большой зал',
      minutesBegin: 900,
      minutesEnd: 960,
    );

    await tester.pumpWidget(
      testApp(ScheduleCard(item: item, clock: fixedClock(), clientId: 255)),
    );

    expect(find.text('сампо Пётр Петров'), findsOneWidget);
    expect(find.text('аренда Пётр Петров'), findsNothing);
    expect(find.text('САМПО'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Большой зал')).dy,
      greaterThan(tester.getTopLeft(find.text('сампо Пётр Петров')).dy),
    );
  });

  testWidgets('time falls back to startsAt/endsAt in branch time',
      (tester) async {
    final item = scheduleItem(
      id: 'g2',
      type: 0,
      title: 'Сальса',
      hallName: 'Зал 1',
      startsAt: DateTime.utc(2026, 11, 19, 12),
      endsAt: DateTime.utc(2026, 11, 19, 13, 30),
    );

    await tester.pumpWidget(testApp(ScheduleCard(item: item, clock: fixedClock())));

    expect(find.text('19:00'), findsOneWidget);
    expect(find.text('90 мин'), findsOneWidget);
  });

  testWidgets('minutesBegin/End win over startsAt/endsAt', (tester) async {
    final item = scheduleItem(
      id: 'g3',
      type: 0,
      title: 'Хип-хоп',
      hallName: 'Зал 1',
      minutesBegin: 600,
      minutesEnd: 660,
      startsAt: DateTime.utc(2026, 11, 19, 12),
      endsAt: DateTime.utc(2026, 11, 19, 13),
    );

    await tester.pumpWidget(testApp(ScheduleCard(item: item, clock: fixedClock())));

    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('19:00'), findsNothing);
  });
}
