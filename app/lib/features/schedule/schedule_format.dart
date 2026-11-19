import '../../core/models/schedule_item.dart';
import '../../core/time/branch_clock.dart';

/// Formatting helpers for the schedule.
///
/// The primary path uses [BranchClock] (branch-local UTC+7, Russian locale).
/// A tiny manual fallback keeps the schedule alive if `intl` locale data has
/// not been initialized yet (for example in a focused widget test), because a
/// date label must never crash the whole home scroll.

const _ruMonthsGenitive = <String>[
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

const _ruWeekdaysShort = <String>[
  'ПН',
  'ВТ',
  'СР',
  'ЧТ',
  'ПТ',
  'СБ',
  'ВС',
];

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// `960` → `16:00`.
String formatMinutesOfDay(int minutes) {
  final normalized = ((minutes % Duration.minutesPerDay) +
          Duration.minutesPerDay) %
      Duration.minutesPerDay;
  return '${_twoDigits(normalized ~/ 60)}:${_twoDigits(normalized % 60)}';
}

/// Start time of a schedule item.
///
/// `minutesBegin` is already branch-local (minutes from midnight) and wins;
/// `startsAt` is only a fallback and is converted to branch time.
String scheduleStartTime(ScheduleItem item, BranchClock clock) {
  final minutes = item.minutesBegin;
  if (minutes != null) return formatMinutesOfDay(minutes);
  final startsAt = item.startsAt;
  if (startsAt == null) return '—';
  try {
    return clock.formatTime(clock.branchDate(startsAt));
  } catch (_) {
    final local = clock.branchDate(startsAt);
    return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }
}

/// Duration in minutes, or `null` when the payload has no usable end.
int? scheduleDurationMinutes(ScheduleItem item) {
  final begin = item.minutesBegin;
  final end = item.minutesEnd;
  if (begin != null && end != null && end > begin) return end - begin;
  final startsAt = item.startsAt;
  final endsAt = item.endsAt;
  if (startsAt != null && endsAt != null) {
    final minutes = endsAt.difference(startsAt).inMinutes;
    if (minutes > 0) return minutes;
  }
  return null;
}

/// `60 мин`, or `null` when the duration is unknown.
String? scheduleDurationText(ScheduleItem item) {
  final minutes = scheduleDurationMinutes(item);
  return minutes == null ? null : '$minutes мин';
}

/// Branch-local header date: `Сегодня, 19 ноября` or `19 ноября`.
String scheduleDayTitle(
  DateTime day,
  DateTime today,
  BranchClock clock,
) {
  final formatted = _formatDay(day, clock);
  return clock.isSameDay(day, today) ? 'Сегодня, $formatted' : formatted;
}

/// Two-letter Russian weekday, e.g. `ПН`.
String scheduleWeekdayShort(DateTime day, BranchClock clock) {
  try {
    return clock.weekdayShort(day).toUpperCase();
  } catch (_) {
    return _ruWeekdaysShort[(day.weekday - 1) % 7];
  }
}

String _formatDay(DateTime day, BranchClock clock) {
  try {
    return clock.formatDay(day);
  } catch (_) {
    return '${day.day} ${_ruMonthsGenitive[(day.month - 1) % 12]}';
  }
}

/// Monday of the week that contains [day].
DateTime scheduleWeekStart(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}
