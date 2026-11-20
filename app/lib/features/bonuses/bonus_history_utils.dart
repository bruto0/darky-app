import '../../core/models/bonus.dart';
import '../../core/time/branch_clock.dart';

const int bonusesPageSize = 20;

class BonusMonthGroup {
  const BonusMonthGroup({required this.label, required this.bonuses});

  final String label;
  final List<Bonus> bonuses;
}

List<Bonus> dedupeBonuses(Iterable<Bonus> bonuses) {
  final seen = <String>{};
  final result = <Bonus>[];
  for (final bonus in bonuses) {
    final id = bonus.id.trim();
    if (id.isEmpty) {
      result.add(bonus);
      continue;
    }
    if (seen.add(id)) result.add(bonus);
  }
  return result;
}

List<Bonus> sortBonusesNewestFirst(Iterable<Bonus> bonuses) {
  final result = bonuses.toList();
  result.sort((a, b) {
    final left = a.createdAt;
    final right = b.createdAt;
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  });
  return result;
}

List<BonusMonthGroup> groupBonusesByMonth(
  Iterable<Bonus> bonuses,
  BranchClock clock,
) {
  final groups = <String, List<Bonus>>{};
  final labels = <String, String>{};
  final undated = <Bonus>[];

  for (final bonus in bonuses) {
    final created = bonus.createdAt;
    if (created == null) {
      undated.add(bonus);
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
    groups.putIfAbsent(key, () => []).add(bonus);
  }

  return [
    for (final entry in groups.entries)
      BonusMonthGroup(label: labels[entry.key]!, bonuses: entry.value),
    if (undated.isNotEmpty)
      BonusMonthGroup(label: 'БЕЗ ДАТЫ', bonuses: undated),
  ];
}

String bonusRowDate(BranchClock clock, Bonus bonus) {
  final created = bonus.createdAt;
  if (created == null) return '—';
  return clock.dateFormat('dd.MM').format(clock.branchDate(created));
}

String bonusDescription(Bonus bonus) {
  final description = bonus.description?.trim();
  if (description != null && description.isNotEmpty) {
    final normalized = description.toLowerCase();
    if (normalized.startsWith('начислен') ||
        normalized.startsWith('списан') ||
        normalized.startsWith('обнулен')) {
      return _capitalize(description);
    }
    final prefix = switch (bonus.type) {
      1 => 'Начисление',
      2 || 3 => 'Списание',
      _ => 'Операция',
    };
    return '$prefix $description';
  }
  final typeText = bonus.typeText?.trim();
  if (typeText != null && typeText.isNotEmpty) return _capitalize(typeText);
  final annotation = bonus.annotation?.trim();
  if (annotation != null && annotation.isNotEmpty) return _capitalize(annotation);
  return 'Операция с баллами';
}

String bonusAmountLabel(Bonus bonus) {
  final amount = bonus.signedAmount;
  if (amount == 0) return '0';
  return amount > 0 ? '+$amount' : '−${amount.abs()}';
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
