import 'dart:async';

import 'package:dance/app/providers.dart';
import 'package:dance/core/data/data_providers.dart';
import 'package:dance/core/models/booking.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/time/branch_clock.dart';
import 'package:dance/core/ui/theme.dart';
import 'package:dance/features/bookings/bookings_card.dart';
import 'package:dance/features/bookings/bookings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  final clock = BranchClock(now: () => DateTime.utc(2026, 11, 20, 4));

  final rentBooking = Booking(
    id: '4001',
    type: 2,
    hallName: 'Средний зал',
    branchName: "D'arky Dance · Главный",
    startsAt: DateTime.parse('2026-11-23T19:00:00+07:00'),
    minutesBegin: 19 * 60,
    minutesEnd: 20 * 60,
  );

  final pastBooking = Booking(
    id: '4000',
    type: 2,
    hallName: 'Малый зал',
    startsAt: DateTime.parse('2026-11-19T19:00:00+07:00'),
    minutesBegin: 19 * 60,
    minutesEnd: 20 * 60,
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    required List<Booking> Function() load,
    VoidCallback? onOpenSchedule,
    ExternalUrlLauncher? launchExternalUrl,
    double textScale = 1.0,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchClockProvider.overrideWithValue(clock),
          bookingsProvider.overrideWith((ref) async => load()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: BookingsScreen(
            onOpenSchedule: onOpenSchedule,
            launchExternalUrl: launchExternalUrl,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders upcoming bookings and hides past ones', (tester) async {
    await pumpScreen(tester, load: () => [pastBooking, rentBooking]);

    expect(find.text('Записи'), findsOneWidget);
    expect(find.text('1 запись'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('НОЯ'), findsOneWidget);
    expect(find.text('АРЕНДА ЗАЛА'), findsOneWidget);
    expect(find.text('Средний зал'), findsOneWidget);
    expect(find.text("D'arky Dance · Главный"), findsOneWidget);
    expect(find.text('19:00–20:00'), findsOneWidget);
    expect(find.text('· понедельник'), findsOneWidget);
    expect(find.text('Отменить запись'), findsOneWidget);
    expect(find.textContaining('не позднее чем за 30 минут'), findsOneWidget);
    expect(find.text('Хотите записаться?'), findsNothing);

    expect(find.text('Малый зал'), findsNothing);
    expect(find.text('19'), findsNothing);
  });

  testWidgets('cards are sorted by date and time', (tester) async {
    final later = Booking(
      id: '2',
      type: 0,
      title: 'Бачата Beginner',
      hallName: 'Большой зал',
      startsAt: DateTime.parse('2026-11-25T19:00:00+07:00'),
      minutesBegin: 19 * 60,
      minutesEnd: 20 * 60,
    );
    final sooner = Booking(
      id: '1',
      type: 1,
      hallName: 'Малый зал',
      startsAt: DateTime.parse('2026-11-21T10:00:00+07:00'),
      minutesBegin: 10 * 60,
      minutesEnd: 11 * 60,
    );

    await pumpScreen(tester, load: () => [later, sooner]);

    expect(find.text('2 записи'), findsOneWidget);
    expect(find.text('БАЧАТА BEGINNER'), findsOneWidget);
    expect(find.text('ИНДИВИДУАЛЬНОЕ ЗАНЯТИЕ'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Малый зал')).dy,
      lessThan(tester.getTopLeft(find.text('Большой зал')).dy),
    );
  });

  testWidgets('cancel button opens the cabinet sheet and launches the URL', (
    tester,
  ) async {
    Uri? launched;
    Future<bool> launcher(Uri uri) async {
      launched = uri;
      return true;
    }

    await pumpScreen(
      tester,
      load: () => [rentBooking],
      launchExternalUrl: launcher,
    );

    await tester.tap(find.text('Отменить запись'));
    await tester.pumpAndSettle();

    expect(find.text('Отмена записи'), findsOneWidget);
    expect(
      find.textContaining('В приложении отмена пока недоступна'),
      findsOneWidget,
    );
    expect(find.text('Открыть кабинет клуба'), findsOneWidget);

    await tester.tap(find.text('Открыть кабинет клуба'));
    await tester.pumpAndSettle();

    expect(
      launched,
      Uri.parse('https://4621c03198bd6735334088.impulsemini.ru/widget/2'),
    );
    expect(find.text('Отмена записи'), findsNothing);
  });

  testWidgets('failed browser launch is reported, not silently dropped', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      load: () => [rentBooking],
      launchExternalUrl: (uri) async => false,
    );

    await tester.tap(find.text('Отменить запись'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть кабинет клуба'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось открыть браузер'), findsOneWidget);
  });

  testWidgets('empty state offers the schedule button', (tester) async {
    var opened = false;
    await pumpScreen(
      tester,
      load: () => [],
      onOpenSchedule: () => opened = true,
    );

    expect(find.text('0 записей'), findsOneWidget);
    expect(find.text('Пока нет записей'), findsOneWidget);
    expect(find.text('Хотите записаться?'), findsNothing);

    await tester.tap(find.text('Открыть расписание'));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('error state shows a reason and retries the provider', (
    tester,
  ) async {
    var attempts = 0;
    await pumpScreen(
      tester,
      load: () {
        attempts++;
        if (attempts == 1) throw const NetworkFailure();
        return [rentBooking];
      },
    );

    expect(find.text('Не удалось загрузить записи'), findsWidgets);
    expect(find.text('Нет соединения с интернетом'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('1 запись'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
    expect(find.text('НОЯ'), findsOneWidget);
  });

  testWidgets('reveals the loaded state after a pending future', (
    tester,
  ) async {
    final completer = Completer<List<Booking>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchClockProvider.overrideWithValue(clock),
          bookingsProvider.overrideWith((ref) => completer.future),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const BookingsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Загружаем записи…'), findsWidgets);

    completer.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('Пока нет записей'), findsOneWidget);
  });

  testWidgets('fits a 360 dp screen at 1.3 text scale', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final later = Booking(
      id: '2',
      type: 0,
      title: 'Бачата Beginner',
      hallName: 'Большой зал',
      branchName: "D'arky Dance · Главный",
      startsAt: DateTime.parse('2026-11-25T19:00:00+07:00'),
      minutesBegin: 19 * 60,
      minutesEnd: 20 * 60,
    );

    await pumpScreen(
      tester,
      load: () => [rentBooking, later],
      onOpenSchedule: () {},
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('2 записи'), findsOneWidget);
    expect(find.text('Отменить запись'), findsNWidgets(2));
    expect(find.text('Хотите записаться?'), findsNothing);
  });
}
