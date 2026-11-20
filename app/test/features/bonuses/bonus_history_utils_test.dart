import 'package:dance/core/models/bonus.dart';
import 'package:dance/core/time/branch_clock.dart';
import 'package:dance/core/ui/plural.dart';
import 'package:dance/features/bonuses/bonus_history_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  final clock = BranchClock(now: () => DateTime.utc(2026, 11, 20, 4));

  test('formats points with Russian plural forms', () {
    expect(formatPoints(1), '1 балл');
    expect(formatPoints(2), '2 балла');
    expect(formatPoints(4), '4 балла');
    expect(formatPoints(5), '5 баллов');
    expect(formatPoints(11), '11 баллов');
    expect(formatPoints(21), '21 балл');
    expect(formatPoints(0), '0 баллов');
  });

  test('parses signed bonus operations and descriptions', () {
    final accrual = Bonus.fromJson({
      'id': 20,
      'type': 1,
      'typeText': 'начисление баллов',
      'sum': 450,
      'sumWithSign': 450,
      'created': 1776777196,
      'descriptionTypeText': 'за покупку абонемента',
      'clientBonus': 900,
    });
    final burn = Bonus.fromJson({
      'id': 49,
      'type': 3,
      'typeText': 'обнуление баллов',
      'sum': 900,
      'sumWithSign': -900,
      'created': 1779191712,
    });

    expect(accrual.signedAmount, 450);
    expect(bonusDescription(accrual), 'Начисление за покупку абонемента');
    expect(bonusAmountLabel(accrual), '+450');
    expect(burn.signedAmount, -900);
    expect(bonusDescription(burn), 'Обнуление баллов');
    expect(bonusAmountLabel(burn), '−900');
  });

  test('sorts newest first and groups by month', () {
    final items = sortBonusesNewestFirst([
      Bonus(id: 'a', createdAt: DateTime.utc(2026, 9, 3)),
      Bonus(id: 'b', createdAt: DateTime.utc(2026, 11, 14)),
      Bonus(id: 'c', createdAt: DateTime.utc(2026, 11, 3)),
    ]);
    final groups = groupBonusesByMonth(items, clock);

    expect(items.map((item) => item.id), ['b', 'c', 'a']);
    expect(groups.map((group) => group.label), ['НОЯБРЬ 2026', 'СЕНТЯБРЬ 2026']);
    expect(groups.first.bonuses.map((item) => item.id), ['b', 'c']);
    expect(bonusRowDate(clock, items.first), '14.11');
  });
}
