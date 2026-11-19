import 'package:dance/features/schedule/schedule_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'test_support.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  test('formats minutes from midnight as HH:mm', () {
    expect(formatMinutesOfDay(0), '00:00');
    expect(formatMinutesOfDay(75), '01:15');
    expect(formatMinutesOfDay(960), '16:00');
    expect(formatMinutesOfDay(1440), '00:00');
  });

  test('start time prefers minutesBegin', () {
    final clock = fixedClock();
    final item = scheduleItem(
      minutesBegin: 615,
      startsAt: DateTime.utc(2026, 11, 19, 12),
    );
    expect(scheduleStartTime(item, clock), '10:15');
  });

  test('start time falls back to startsAt in branch time', () {
    final clock = fixedClock();
    final item = scheduleItem(startsAt: DateTime.utc(2026, 11, 19, 12));
    expect(scheduleStartTime(item, clock), '19:00');
  });

  test('duration prefers minute range and falls back to timestamps', () {
    expect(
      scheduleDurationMinutes(
        scheduleItem(minutesBegin: 600, minutesEnd: 690),
      ),
      90,
    );
    expect(scheduleDurationText(scheduleItem(minutesBegin: 600, minutesEnd: 690)),
        '90 мин');
    expect(
      scheduleDurationMinutes(
        scheduleItem(
          startsAt: DateTime.utc(2026, 11, 19, 12),
          endsAt: DateTime.utc(2026, 11, 19, 12, 45),
        ),
      ),
      45,
    );
    expect(scheduleDurationText(scheduleItem()), isNull);
  });

  test('day title marks branch today', () {
    final clock = fixedClock();
    final today = clock.dayStart(clock.branchNow());
    expect(
      scheduleDayTitle(DateTime(2026, 11, 19), today, clock),
      'Сегодня, 19 ноября',
    );
    expect(
      scheduleDayTitle(DateTime(2026, 11, 20), today, clock),
      '20 ноября',
    );
  });

  test('weekday labels are short Russian names', () {
    final clock = fixedClock();
    expect(scheduleWeekdayShort(DateTime(2026, 11, 16), clock), 'ПН');
    expect(scheduleWeekdayShort(DateTime(2026, 11, 22), clock), 'ВС');
  });

  test('week starts on Monday', () {
    expect(
      scheduleWeekStart(DateTime(2026, 11, 19, 15, 30)),
      DateTime(2026, 11, 16),
    );
    expect(
      scheduleWeekStart(DateTime(2026, 11, 16)),
      DateTime(2026, 11, 16),
    );
    expect(
      scheduleWeekStart(DateTime(2026, 11, 22)),
      DateTime(2026, 11, 16),
    );
  });
}
