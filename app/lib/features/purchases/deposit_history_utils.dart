import 'package:intl/intl.dart';

import '../../core/models/deposit.dart';
import '../../core/network/api_failure.dart';
import '../../core/time/branch_clock.dart';

/// Page size used by `depositsPageProvider` (see `WidgetLkRepository.deposits`).
const int depositsPageSize = 20;

/// A month section of the purchases history. The API is already sorted by
/// `created desc`, so groups keep that order; timestamps are converted to the
/// branch timezone before the month is chosen.
class DepositMonthGroup {
  const DepositMonthGroup({required this.label, required this.deposits});

  final String label;
  final List<Deposit> deposits;
}

/// Removes duplicate operations that can appear on the page boundary while
/// infinite scrolling. The first occurrence wins, the original order is kept.
List<Deposit> dedupeDeposits(Iterable<Deposit> deposits) {
  final seen = <String>{};
  final result = <Deposit>[];
  for (final deposit in deposits) {
    final id = deposit.id.trim();
    if (id.isEmpty) {
      result.add(deposit);
      continue;
    }
    if (seen.add(id)) result.add(deposit);
  }
  return result;
}

/// Groups operations under uppercase Russian month headers (`НОЯБРЬ 2026`).
///
/// A deposit without `created` lands in the trailing `БЕЗ ДАТЫ` group, so the
/// sorted part of the history is not interrupted by a malformed row.
List<DepositMonthGroup> groupDepositsByMonth(
  Iterable<Deposit> deposits,
  BranchClock clock,
) {
  final groups = <String, List<Deposit>>{};
  final labels = <String, String>{};
  final undated = <Deposit>[];

  for (final deposit in deposits) {
    final created = deposit.createdAt;
    if (created == null) {
      undated.add(deposit);
      continue;
    }
    final branchDate = clock.branchDate(created);
    final key = '${branchDate.year}-${branchDate.month}';
    labels.putIfAbsent(
      key,
      () => clock
          .dateFormat('LLLL yyyy')
          .format(DateTime(branchDate.year, branchDate.month))
          .toUpperCase(),
    );
    groups.putIfAbsent(key, () => []).add(deposit);
  }

  return [
    for (final entry in groups.entries)
      DepositMonthGroup(label: labels[entry.key]!, deposits: entry.value),
    if (undated.isNotEmpty)
      DepositMonthGroup(label: 'БЕЗ ДАТЫ', deposits: undated),
  ];
}

/// «9 операций», «1 операция», «2 операции».
String formatOperationsCount(int count) {
  return '$count ${_plural(count, 'операция', 'операции', 'операций')}';
}

/// Subtitle from DESIGN.md §4.5: «9 операций · оплата и пополнения».
String formatPurchasesSubtitle(int count) {
  return '${formatOperationsCount(count)} · оплата и пополнения';
}

/// Row date in branch time, e.g. `10.11`.
String depositRowDate(BranchClock clock, Deposit deposit) {
  final created = deposit.createdAt;
  if (created == null) return '—';
  return clock.dateFormat('dd.MM').format(clock.branchDate(created));
}

/// Description line: `typeText` with a capital first letter, then `title`.
String depositTitle(Deposit deposit) {
  final typeText = deposit.typeText?.trim();
  if (typeText != null && typeText.isNotEmpty) return _capitalize(typeText);
  final title = deposit.title?.trim();
  if (title != null && title.isNotEmpty) return _capitalize(title);
  return 'Операция';
}

/// Green amount from `sumWithSign`, falling back to `sum`/`amount`.
///
/// The approved mockup shows payments and top-ups as positive amounts, so the
/// value is displayed without a sign. `sumWithSign` may be a number or an
/// already formatted vendor string; both are normalized to `10 350 ₽`.
String depositAmountLabel(Deposit deposit) {
  final signed = deposit.sumWithSign?.trim();
  final fromSigned = signed == null || signed.isEmpty
      ? null
      : _parseMoney(signed);
  final value = fromSigned ?? deposit.sum ?? deposit.amount;
  if (value == null) return '—';
  return '${_formatMoney(value.abs())} ₽';
}

/// «Картой · абонемент № 514» when payment/account details are present.
String? depositPaymentLine(Deposit deposit) {
  final parts = <String>[];
  final payment = deposit.paymentText?.trim();
  if (payment != null && payment.isNotEmpty) {
    parts.add(_capitalize(payment));
  }
  final number = deposit.targetNumber;
  if (number != null) parts.add('абонемент № $number');
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Human-readable, technical-free error line for the error states.
String historyErrorText(Object? error) {
  if (error is UnauthorizedFailure) {
    return 'Сессия истекла. Войдите снова, чтобы увидеть историю.';
  }
  if (error is NetworkFailure) {
    return 'Нет соединения. Проверьте сеть и попробуйте ещё раз.';
  }
  if (error is TimeoutFailure) {
    return 'Сервер долго не отвечает. Попробуйте ещё раз.';
  }
  if (error is VendorFailure) {
    return 'Сервис клуба временно недоступен. Попробуйте позже.';
  }
  if (error is ParseFailure) {
    return 'Не удалось разобрать ответ сервера. Попробуйте ещё раз.';
  }
  return 'Не удалось загрузить данные. Попробуйте ещё раз.';
}

String _formatMoney(num value) {
  return NumberFormat('#,##0', 'ru_RU').format(value);
}

num? _parseMoney(String raw) {
  var cleaned = raw.replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
  cleaned = cleaned.replaceAll('₽', '');
  cleaned = cleaned.replaceAll(RegExp(r'руб\.?', caseSensitive: false), '');
  cleaned = cleaned.replaceAll('+', '');
  cleaned = cleaned.replaceAll(',', '.');
  return num.tryParse(cleaned);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _plural(int count, String one, String few, String many) {
  final mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return many;
  return switch (count % 10) {
    1 => one,
    2 || 3 || 4 => few,
    _ => many,
  };
}
