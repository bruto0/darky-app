import 'dart:ui' show Color;

import '../../core/models/visit.dart';
import '../../core/network/api_failure.dart';
import '../../core/time/branch_clock.dart';

/// Page size used by `visitsPageProvider` (see `WidgetLkRepository.visits`).
const int visitsPageSize = 20;

/// Removes duplicate visits that can appear on the page boundary while
/// infinite scrolling. The first occurrence wins, the original order is kept.
List<Visit> dedupeVisits(Iterable<Visit> visits) {
  final seen = <String>{};
  final result = <Visit>[];
  for (final visit in visits) {
    final id = visit.id.trim();
    if (id.isEmpty) {
      result.add(visit);
      continue;
    }
    if (seen.add(id)) result.add(visit);
  }
  return result;
}

/// «89 посещений», «1 посещение», «2 посещения».
String formatVisitsCount(int count) {
  return '$count ${_plural(count, 'посещение', 'посещения', 'посещений')}';
}

/// Branch-local date of the visit, e.g. `17.11.2026`.
///
/// The API stores an absolute instant (`visitDate`/`visit_date`); the branch
/// clock converts it to UTC+7 so the device timezone never changes the date.
String visitDateLabel(BranchClock clock, Visit visit) {
  final visitedAt = visit.visitedAt;
  if (visitedAt == null) return '—';
  return clock.dateFormat('dd.MM.yyyy').format(clock.branchDate(visitedAt));
}

/// «Абонемент № 514» for account visits, «Разовое занятие» otherwise.
String visitServiceLabel(Visit visit) {
  final number = visit.serviceNumber;
  final byAccount =
      visit.byAccount == true || (visit.byAccount == null && number != null);
  if (!byAccount) return 'Разовое занятие';
  return number == null ? 'Абонемент' : 'Абонемент № $number';
}

/// Lesson/style title with a safe fallback when the vendor omits it.
String visitTitle(Visit visit) {
  final title = visit.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  final target = visit.targetName?.trim();
  if (target != null && target.isNotEmpty) return target;
  return 'Занятие';
}

/// «Кальдерон Диего, Губина Наталья Леонидовна» or null when nobody came back.
String? visitTeachers(Visit visit) {
  final names = visit.teacherNames
      ?.map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList();
  if (names != null && names.isNotEmpty) return names.join(', ');
  final single = visit.teacherName?.trim();
  if (single == null || single.isEmpty) return null;
  return single;
}

/// Branch shown next to the pin. Null when the API did not return a branch.
String? visitBranchName(Visit visit) {
  final branch = visit.branchName?.trim();
  if (branch == null || branch.isEmpty) return null;
  return branch;
}

/// Style rail color from `target.style.color`; null means "use theme accent".
Color? visitStyleColor(Visit visit) => parseColorHex(visit.styleColor);

/// Parses `#RGB`, `#RRGGBB`, `RRGGBB`, `0xAARRGGBB` and `AARRGGBB`.
///
/// The club styles use six-digit hex values (e.g. `D1D1D1`), so an eight-digit
/// value is treated as ARGB for Flutter compatibility. Invalid values return
/// null so the caller can fall back to the palette accent instead of guessing.
Color? parseColorHex(String? raw) {
  if (raw == null) return null;
  var value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) {
    value = value.substring(1);
  } else if (value.toLowerCase().startsWith('0x')) {
    value = value.substring(2);
  }
  if (value.length == 3) {
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      buffer.write('$char$char');
    }
    value = buffer.toString();
  }
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

/// Human-readable, technical-free error line for the error/empty states.
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

String _plural(int count, String one, String few, String many) {
  final mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return many;
  return switch (count % 10) {
    1 => one,
    2 || 3 || 4 => few,
    _ => many,
  };
}
