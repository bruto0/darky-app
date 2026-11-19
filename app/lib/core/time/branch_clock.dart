import 'package:intl/intl.dart';

/// All schedule times are branch-local (UTC+7), independent of the device.
class BranchClock {
  BranchClock({
    this.offset = const Duration(hours: 7),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration offset;
  final DateTime Function() _now;

  DateTime now() => _now().toUtc();

  DateTime branchNow() => _wallClock(now().add(offset));

  DateTime branchDate(DateTime instant) => _wallClock(instant.toUtc().add(offset));

  DateTime _wallClock(DateTime instant) {
    return DateTime(
      instant.year,
      instant.month,
      instant.day,
      instant.hour,
      instant.minute,
      instant.second,
      instant.millisecond,
      instant.microsecond,
    );
  }

  DateTime dayStart(DateTime branchDate) {
    return DateTime(branchDate.year, branchDate.month, branchDate.day);
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String formatDay(DateTime date) => DateFormat('d MMMM', 'ru_RU').format(date);

  String formatTime(DateTime date) => DateFormat('HH:mm', 'ru_RU').format(date);

  String weekdayShort(DateTime date) =>
      DateFormat('EE', 'ru_RU').format(date);

  String weekdayFull(DateTime date) => DateFormat('EEEE', 'ru_RU').format(date);

  DateFormat dateFormat(String pattern) => DateFormat(pattern, 'ru_RU');
}
