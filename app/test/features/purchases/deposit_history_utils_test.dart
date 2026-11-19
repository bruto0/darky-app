import 'package:dance/core/models/deposit.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/time/branch_clock.dart';
import 'package:dance/features/purchases/deposit_history_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Deposit buildDeposit({
  required String id,
  String? typeText,
  String? title,
  num? sum,
  num? amount,
  String? sumWithSign,
  String? paymentText,
  int? targetNumber,
  DateTime? createdAt,
}) {
  return Deposit(
    id: id,
    typeText: typeText,
    title: title,
    sum: sum,
    amount: amount,
    sumWithSign: sumWithSign,
    paymentText: paymentText,
    targetNumber: targetNumber,
    createdAt: createdAt,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  group('dedupeDeposits', () {
    test('removes duplicates across page boundaries and keeps page order', () {
      final first = buildDeposit(id: '3001', typeText: 'Пополнение');
      final second = buildDeposit(id: '3002', typeText: 'Оплата');
      final repeated = buildDeposit(id: '3001', typeText: 'Дубль');

      final result = dedupeDeposits([first, second, repeated]);

      expect(result, [first, second]);
    });

    test('keeps operations with an empty id', () {
      final result = dedupeDeposits([
        buildDeposit(id: ''),
        buildDeposit(id: ''),
      ]);

      expect(result, hasLength(2));
    });

    test('returns an empty list for empty input', () {
      expect(dedupeDeposits(const []), isEmpty);
    });
  });

  group('formatOperationsCount', () {
    test('uses Russian plural forms', () {
      expect(formatOperationsCount(1), '1 операция');
      expect(formatOperationsCount(2), '2 операции');
      expect(formatOperationsCount(5), '5 операций');
      expect(formatOperationsCount(9), '9 операций');
      expect(formatOperationsCount(11), '11 операций');
      expect(formatOperationsCount(21), '21 операция');
      expect(formatOperationsCount(22), '22 операции');
    });

    test('builds the header subtitle from DESIGN.md §4.5', () {
      expect(
        formatPurchasesSubtitle(9),
        '9 операций · оплата и пополнения',
      );
    });
  });

  group('groupDepositsByMonth', () {
    final clock = BranchClock(offset: const Duration(hours: 7));

    test('groups operations by branch month in first-seen order', () {
      final november = buildDeposit(
        id: '1',
        createdAt: DateTime.utc(2026, 11, 10, 5),
      );
      final september = buildDeposit(
        id: '2',
        createdAt: DateTime.utc(2026, 9, 29, 5),
      );
      final anotherNovember = buildDeposit(
        id: '3',
        createdAt: DateTime.utc(2026, 11, 1, 5),
      );

      final groups = groupDepositsByMonth(
        [november, september, anotherNovember],
        clock,
      );

      expect(groups.map((group) => group.label), [
        'НОЯБРЬ 2026',
        'СЕНТЯБРЬ 2026',
      ]);
      expect(groups.first.deposits, [november, anotherNovember]);
      expect(groups.last.deposits, [september]);
    });

    test('uses the branch timezone for the month boundary', () {
      // 31.10 18:30 UTC is already 01.11 01:30 in the UTC+7 branch.
      final lateOctober = buildDeposit(
        id: '1',
        createdAt: DateTime.utc(2026, 10, 31, 18, 30),
      );

      final groups = groupDepositsByMonth([lateOctober], clock);

      expect(groups.single.label, 'НОЯБРЬ 2026');
      expect(depositRowDate(clock, lateOctober), '01.11');
    });

    test('puts undated operations into a trailing БЕЗ ДАТЫ group', () {
      final dated = buildDeposit(
        id: '1',
        createdAt: DateTime.utc(2026, 11, 10, 5),
      );
      final undated = buildDeposit(id: '2');

      final groups = groupDepositsByMonth([dated, undated], clock);

      expect(groups.map((group) => group.label), [
        'НОЯБРЬ 2026',
        'БЕЗ ДАТЫ',
      ]);
      expect(groups.last.deposits, [undated]);
    });

    test('merges the same month arriving on different pages', () {
      final pageOne = buildDeposit(
        id: '1',
        createdAt: DateTime.utc(2026, 11, 20, 5),
      );
      final pageTwo = buildDeposit(
        id: '2',
        createdAt: DateTime.utc(2026, 11, 5, 5),
      );

      final groups = groupDepositsByMonth([pageOne, pageTwo], clock);

      expect(groups, hasLength(1));
      expect(groups.single.label, 'НОЯБРЬ 2026');
      expect(groups.single.deposits, [pageOne, pageTwo]);
    });

    test('returns no groups for empty input', () {
      expect(groupDepositsByMonth(const [], clock), isEmpty);
    });
  });

  group('depositRowDate', () {
    final clock = BranchClock(offset: const Duration(hours: 7));

    test('formats day and month in branch time', () {
      final deposit = buildDeposit(
        id: '1',
        createdAt: DateTime.utc(2026, 11, 10, 5),
      );

      expect(depositRowDate(clock, deposit), '10.11');
    });

    test('returns a dash for a missing date', () {
      expect(depositRowDate(clock, buildDeposit(id: '1')), '—');
    });
  });

  group('depositTitle', () {
    test('prefers typeText and capitalizes it', () {
      expect(
        depositTitle(
          buildDeposit(id: '1', typeText: 'оплата группового абонемента'),
        ),
        'Оплата группового абонемента',
      );
    });

    test('falls back to title', () {
      expect(
        depositTitle(buildDeposit(id: '1', title: 'пополнение счета')),
        'Пополнение счета',
      );
    });

    test('falls back to a neutral label', () {
      expect(depositTitle(buildDeposit(id: '1')), 'Операция');
    });
  });

  group('depositAmountLabel', () {
    test('normalizes a formatted sumWithSign', () {
      expect(
        depositAmountLabel(
          buildDeposit(id: '1', sumWithSign: '+10 350 ₽'),
        ),
        '10\u00A0350 ₽',
      );
    });

    test('formats a numeric sumWithSign string', () {
      expect(
        depositAmountLabel(buildDeposit(id: '1', sumWithSign: '9900')),
        '9\u00A0900 ₽',
      );
    });

    test('shows payments as positive amounts like the approved mockup', () {
      expect(
        depositAmountLabel(
          buildDeposit(id: '1', sumWithSign: '-12 000 ₽'),
        ),
        '12\u00A0000 ₽',
      );
    });

    test('falls back to sum when sumWithSign is missing', () {
      expect(
        depositAmountLabel(buildDeposit(id: '1', sum: -12000)),
        '12\u00A0000 ₽',
      );
    });

    test('falls back to amount when sum is missing', () {
      expect(
        depositAmountLabel(buildDeposit(id: '1', amount: 5000)),
        '5\u00A0000 ₽',
      );
    });

    test('returns a dash when there is no amount at all', () {
      expect(depositAmountLabel(buildDeposit(id: '1')), '—');
    });
  });

  group('depositPaymentLine', () {
    test('joins payment method and account number', () {
      expect(
        depositPaymentLine(
          buildDeposit(
            id: '1',
            paymentText: 'картой',
            targetNumber: 514,
          ),
        ),
        'Картой · абонемент № 514',
      );
    });

    test('omits the account part when there is no number', () {
      expect(
        depositPaymentLine(
          buildDeposit(id: '1', paymentText: 'Картой'),
        ),
        'Картой',
      );
    });

    test('shows only the account when payment is missing', () {
      expect(
        depositPaymentLine(buildDeposit(id: '1', targetNumber: 381)),
        'абонемент № 381',
      );
    });

    test('returns null when neither is present', () {
      expect(depositPaymentLine(buildDeposit(id: '1')), isNull);
    });
  });

  group('historyErrorText', () {
    test('maps known failures to human messages', () {
      expect(
        historyErrorText(const NetworkFailure()),
        contains('Нет соединения'),
      );
      expect(
        historyErrorText(const UnauthorizedFailure()),
        contains('Сессия истекла'),
      );
      expect(
        historyErrorText(const TimeoutFailure()),
        contains('долго не отвечает'),
      );
    });

    test('never exposes a technical message', () {
      final message = historyErrorText(StateError('secret=abc'));

      expect(message, isNot(contains('secret')));
      expect(message, isNot(contains('StateError')));
    });
  });
}
