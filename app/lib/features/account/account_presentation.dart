import 'package:material_ui/material_ui.dart';

import '../../core/models/account.dart';
import '../../core/storage/session.dart';
import '../../core/ui/theme.dart';

/// Presentation-only helpers shared by the account card and the home header.
///
/// Keeping the formatting here makes the copy and the freeze rules testable
/// without pumping a full screen or creating a network-backed provider.

String accountTitle(Account account) {
  final raw = account.typeName.trim();
  if (raw.isEmpty) return 'Абонемент';
  if (raw.toLowerCase().startsWith('абонемент')) return raw;
  return switch (raw.toUpperCase()) {
    'ПРОФИ' => 'Абонемент профи',
    'СТАНДАРТ' => 'Абонемент стандарт',
    _ => 'Абонемент ${raw.toLowerCase()}',
  };
}

String accountStatusLabel(Account account) {
  if (account.closed) return 'ЗАКРЫТ';
  if (account.freeze) return 'ЗАМОРОЖЕН';
  if (!account.active) return 'НЕАКТИВЕН';
  final status = account.statusName?.trim();
  if (status != null && status.isNotEmpty) return status.toUpperCase();
  return 'АКТИВЕН';
}

/// Why the per-account freeze action cannot be shown, or `null` when it can.
String? freezeUnavailableReason(Account account) {
  if (account.freezeAvailable) return null;
  if (account.freeze) return 'Абонемент заморожен';
  if (account.closed) return 'Абонемент закрыт';
  if (!account.active) return 'Абонемент неактивен';
  if (!account.freezeEnable) return 'Заморозка не предусмотрена тарифом';
  if (account.freezeDaysLeft <= 0) {
    return account.freezeDaysTotal <= 0
        ? 'Заморозка не предусмотрена тарифом'
        : 'Дни заморозки закончились';
  }
  return 'Заморозка недоступна';
}

const _ruMonths = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String formatRuDate(DateTime date) =>
    '${date.day} ${_ruMonths[date.month - 1]} ${date.year}';

String? validUntilLabel(DateTime? date) =>
    date == null ? null : 'Действует до ${formatRuDate(date)}';

class AccountCounter {
  const AccountCounter({required this.value, required this.label});

  final String value;
  final String label;
}

/// The 2x2 counter grid from the design: visits, freeze days and any
/// count-based packets returned by the club widget.
List<AccountCounter> accountCounters(Account account) {
  final visitsLabel = _isIndividual(account)
      ? 'индивидуальных занятий'
      : 'занятий';
  final counters = <AccountCounter>[
    AccountCounter(
      value: '${account.visitsLeft} / ${account.visitsTotal}',
      label: visitsLabel,
    ),
  ];

  if (account.freezeDaysTotal > 0 || account.freezeDaysLeft > 0) {
    final total = account.freezeDaysTotal > 0
        ? account.freezeDaysTotal
        : account.freezeDaysLeft;
    counters.add(
      AccountCounter(
        value: '${account.freezeDaysLeft} / $total',
        label: 'дней заморозки',
      ),
    );
  }

  for (final packet in account.packets) {
    final count = packet.count;
    if (count == null || count <= 0) continue;
    final used = (packet.used ?? 0).clamp(0, count);
    counters.add(
      AccountCounter(
        value: '${count - used} / $count',
        label: packet.typeName?.trim().isNotEmpty == true
            ? packet.typeName!.toLowerCase()
            : 'пакет',
      ),
    );
  }

  return counters;
}

String accountVisitsLabel(Account account) =>
    _isIndividual(account) ? 'индивидуальных занятий' : 'занятий';

/// Cards of the group ("Профи" pink) type keep the branded gradient from the
/// palette; individual accounts get a green tint, matching the web widget.
List<Color> accountGradientFor(Account account, AppPalette palette) {
  final custom = parseAccountColor(account.typeColor);
  if (custom != null) return _tintGradient(custom, palette);
  if (_isIndividual(account)) return _tintGradient(palette.green, palette);
  return palette.accountGradient;
}

bool _isIndividual(Account account) {
  if (account.entity == 'individualAccount') return true;
  if (account.entity == 'groupAccount') return false;
  final name = account.typeName.toLowerCase();
  return name.contains('стандарт') || name.contains('индивидуаль');
}

List<Color> _tintGradient(Color accent, AppPalette palette) {
  Color tint(double amount) => Color.lerp(palette.surface, accent, amount)!;
  return [tint(0.24), tint(0.46), tint(0.33)];
}

/// Accepts `#RRGGBB`, `RRGGBB`, `#AARRGGBB` and `0xAARRGGBB`.
Color? parseAccountColor(String? raw) {
  if (raw == null) return null;
  var value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) value = value.substring(1);
  if (value.startsWith('0x') || value.startsWith('0X')) {
    value = value.substring(2);
  }
  if (value.length == 3) {
    value = value.split('').map((char) => '$char$char').join();
  }
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? null : Color(parsed);
}

String profileDisplayName(ClientProfile profile) {
  final parts = [
    profile.firstName,
    profile.lastName,
  ].where((part) => part.trim().isNotEmpty).toList();
  final name = parts.join(' ').trim();
  return name.isEmpty ? "Гость D'arky" : name;
}

String profileInitials(ClientProfile profile) {
  final initials = [
    _firstLetter(profile.firstName),
    _firstLetter(profile.lastName),
  ].where((letter) => letter.isNotEmpty).join();
  return initials.isEmpty ? 'D' : initials;
}

String _firstLetter(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final firstWord = trimmed.split(RegExp(r'\s+')).first;
  return firstWord.substring(0, 1).toUpperCase();
}

String profileBranchLine(ClientProfile profile) {
  final branch = profile.branchName?.trim();
  if (branch == null || branch.isEmpty) return "D'arky Dance";
  return "D'arky Dance · $branch";
}
