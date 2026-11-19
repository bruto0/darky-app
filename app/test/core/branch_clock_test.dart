import 'package:dance/core/time/branch_clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  test('branch time is UTC+7 regardless of device timezone', () {
    final clock = BranchClock(
      now: () => DateTime.utc(2026, 11, 18, 17, 30),
    );

    expect(clock.branchNow(), DateTime(2026, 11, 19, 0, 30));
    expect(clock.formatDay(clock.branchNow()), '19 ноября');
    expect(clock.formatTime(clock.branchNow()), '00:30');
    expect(clock.weekdayShort(clock.branchNow()), 'чт');
  });

  test('day start and same-day comparison', () {
    final clock = BranchClock(now: () => DateTime.utc(2026, 11, 18, 17));
    final branch = clock.branchNow();
    final start = clock.dayStart(branch);

    expect(start, DateTime(2026, 11, 19));
    expect(clock.isSameDay(start, branch), isTrue);
    expect(clock.isSameDay(start, start.add(const Duration(days: 1))), isFalse);
  });
}
