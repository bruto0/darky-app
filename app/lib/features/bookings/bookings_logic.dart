import '../../core/models/booking.dart';
import '../../core/network/api_failure.dart';
import '../../core/time/branch_clock.dart';

/// Short Russian month labels used by the date badge (`23 НОЯ`).
const List<String> _shortMonths = [
  'янв',
  'фев',
  'мар',
  'апр',
  'май',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];

/// Russian plural form for [count].
///
/// `1 запись`, `2 записи`, `5 записей`, `11 записей`, `21 запись`.
String russianPlural(
  int count, {
  required String one,
  required String few,
  required String many,
}) {
  final mod100 = count.abs() % 100;
  final mod10 = mod100 % 10;
  if (mod100 >= 11 && mod100 <= 14) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}

/// Subtitle for the screen header: `1 запись`, `2 записи`, `5 записей`.
String bookingsCountLabel(int count) {
  final form = russianPlural(
    count,
    one: 'запись',
    few: 'записи',
    many: 'записей',
  );
  return '$count $form';
}

String bookingMonthShort(DateTime branchDate) {
  return _shortMonths[branchDate.month - 1].toUpperCase();
}

/// Date badge text, e.g. `23 НОЯ`.
String bookingDateBadge(DateTime branchDate) {
  return '${branchDate.day} ${bookingMonthShort(branchDate)}';
}

/// Wall-clock start of a booking in the branch timezone.
///
/// `Booking.startsAt`/`date` may arrive either as a UTC instant (Unix seconds
/// or an ISO string with an offset) or as a naive branch-local string. A UTC
/// instant is converted with [BranchClock]; a naive value is already club time
/// and is used as is, so the device timezone never leaks into the list.
DateTime? bookingStart(BranchClock clock, Booking booking) {
  final instant = booking.startsAt ?? booking.date;
  if (instant == null) return null;
  if (instant.isUtc) return clock.branchDate(instant);
  return DateTime(
    instant.year,
    instant.month,
    instant.day,
    instant.hour,
    instant.minute,
    instant.second,
  );
}

/// Expected bookings only: past ones are hidden and the rest is sorted by
/// start ascending (ties are broken by hall/type so the order is stable).
///
/// A booking without any date cannot be proven upcoming, so it is skipped.
List<Booking> upcomingBookings(Iterable<Booking> bookings, BranchClock clock) {
  final now = clock.branchNow();
  final entries = <({Booking booking, DateTime start})>[];
  for (final booking in bookings) {
    final start = bookingStart(clock, booking);
    if (start == null) continue;
    if (start.isBefore(now)) continue;
    entries.add((booking: booking, start: start));
  }
  entries.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    if (byStart != 0) return byStart;
    final byTitle = bookingTitle(a.booking).compareTo(bookingTitle(b.booking));
    if (byTitle != 0) return byTitle;
    return a.booking.id.compareTo(b.booking.id);
  });
  return [for (final entry in entries) entry.booking];
}

/// `HH:mm` for minutes from midnight (`minutesBegin`/`minutesEnd`).
String formatMinutesOfDay(int minutes) {
  final normalized = minutes % (24 * 60);
  final hours = (normalized ~/ 60).toString().padLeft(2, '0');
  final mins = (normalized % 60).toString().padLeft(2, '0');
  return '$hours:$mins';
}

/// Time range of a booking: `19:00–20:00` when both bounds are known,
/// otherwise the start only. `minutesBegin`/`minutesEnd` are club-local and
/// win over an absolute instant.
String bookingTimeRange(BranchClock clock, Booking booking) {
  final begin = booking.minutesBegin;
  final end = booking.minutesEnd;
  final start = bookingStart(clock, booking);
  final startLabel = begin != null
      ? formatMinutesOfDay(begin)
      : start == null
      ? null
      : clock.formatTime(start);
  if (startLabel == null) return 'Время уточняется';
  if (end != null) return '$startLabel–${formatMinutesOfDay(end)}';
  return startLabel;
}

/// The booking type shown as a caption: rent, individual or the group name.
String bookingCaption(Booking booking) {
  if (booking.isRent) return 'Аренда зала';
  if (booking.isIndividual) return 'Индивидуальное занятие';
  final title = booking.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  return 'Групповое занятие';
}

/// The main card title: the hall, falling back to the booking title.
String bookingTitle(Booking booking) {
  final hall = booking.hallName?.trim();
  if (hall != null && hall.isNotEmpty) return hall;
  if (booking.isRent) return 'Аренда зала';
  if (booking.isIndividual) return 'Индивидуальное занятие';
  final title = booking.title?.trim();
  if (title != null && title.isNotEmpty) return title;
  return 'Занятие';
}

/// Branch name for the card meta line, or `null` when the API omitted it.
String? bookingBranch(Booking booking) {
  final branch = booking.branchName?.trim();
  return branch == null || branch.isEmpty ? null : branch;
}

/// Human-readable reason for the error state; vendor internals never leak.
String bookingsErrorMessage(Object? error) {
  return switch (error) {
    NetworkFailure() => 'Нет соединения с интернетом',
    TimeoutFailure() => 'Сервер долго не отвечает',
    UnauthorizedFailure() => 'Сессия истекла, войдите снова',
    VendorFailure() => 'Сервис клуба временно недоступен',
    _ => 'Проверьте соединение и попробуйте снова',
  };
}
