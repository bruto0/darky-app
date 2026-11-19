import 'package:dance/core/models/booking.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/time/branch_clock.dart';
import 'package:dance/features/bookings/bookings_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  group('russian plural', () {
    test('bookings count label uses запись/записи/записей', () {
      expect(bookingsCountLabel(0), '0 записей');
      expect(bookingsCountLabel(1), '1 запись');
      expect(bookingsCountLabel(2), '2 записи');
      expect(bookingsCountLabel(4), '4 записи');
      expect(bookingsCountLabel(5), '5 записей');
      expect(bookingsCountLabel(11), '11 записей');
      expect(bookingsCountLabel(12), '12 записей');
      expect(bookingsCountLabel(14), '14 записей');
      expect(bookingsCountLabel(21), '21 запись');
      expect(bookingsCountLabel(22), '22 записи');
      expect(bookingsCountLabel(25), '25 записей');
      expect(bookingsCountLabel(101), '101 запись');
      expect(bookingsCountLabel(111), '111 записей');
    });

    test('generic helper works for any noun', () {
      String item(int count) =>
          russianPlural(count, one: 'товар', few: 'товара', many: 'товаров');
      expect(item(1), 'товар');
      expect(item(3), 'товара');
      expect(item(7), 'товаров');
      expect(item(0), 'товаров');
      expect(item(13), 'товаров');
      expect(item(23), 'товара');
    });
  });

  group('upcoming bookings', () {
    final clock = BranchClock(now: () => DateTime.utc(2026, 11, 20, 4));

    test('now is 11:00 in the club timezone', () {
      expect(clock.branchNow(), DateTime(2026, 11, 20, 11));
    });

    test('past bookings are hidden and future ones sorted ascending', () {
      final bookings = [
        Booking(id: 'late', startsAt: DateTime.utc(2026, 11, 23, 12)),
        Booking(id: 'past', startsAt: DateTime.utc(2026, 11, 19, 12)),
        Booking(id: 'early', startsAt: DateTime.utc(2026, 11, 20, 5)),
        Booking(id: 'undated'),
      ];

      final result = upcomingBookings(bookings, clock);

      expect(result.map((booking) => booking.id), ['early', 'late']);
    });

    test('a booking starting exactly now stays upcoming', () {
      final result = upcomingBookings([
        Booking(id: 'now', startsAt: DateTime.utc(2026, 11, 20, 4)),
      ], clock);
      expect(result.map((booking) => booking.id), ['now']);
    });

    test('naive branch-local dates are compared as club time', () {
      final bookings = [
        Booking(id: 'later', startsAt: DateTime.parse('2026-11-21T19:00:00')),
        Booking(id: 'gone', startsAt: DateTime.parse('2026-11-20T10:59:00')),
      ];

      final result = upcomingBookings(bookings, clock);

      expect(result.map((booking) => booking.id), ['later']);
    });

    test('fallback to Booking.date when startsAt is absent', () {
      final result = upcomingBookings([
        Booking(id: 'dated', date: DateTime.parse('2026-11-22T09:00:00+07:00')),
      ], clock);
      expect(result.map((booking) => booking.id), ['dated']);
    });

    test('ties are broken deterministically', () {
      final result = upcomingBookings([
        Booking(
          id: 'b',
          title: 'Бачата',
          startsAt: DateTime.utc(2026, 11, 21, 12),
        ),
        Booking(
          id: 'a',
          title: 'Аэро',
          startsAt: DateTime.utc(2026, 11, 21, 12),
        ),
      ], clock);
      expect(result.map((booking) => booking.id), ['a', 'b']);
    });
  });

  group('formatting', () {
    final clock = BranchClock(now: () => DateTime.utc(2026, 11, 20, 4));

    test('date badge is "day MONTH" in caps', () {
      expect(bookingDateBadge(DateTime(2026, 11, 23)), '23 НОЯ');
      expect(bookingDateBadge(DateTime(2027, 1, 1)), '1 ЯНВ');
      expect(bookingDateBadge(DateTime(2026, 5, 9)), '9 МАЙ');
    });

    test('minutes are formatted with leading zeros', () {
      expect(formatMinutesOfDay(0), '00:00');
      expect(formatMinutesOfDay(9 * 60 + 5), '09:05');
      expect(formatMinutesOfDay(19 * 60), '19:00');
      expect(formatMinutesOfDay(23 * 60 + 59), '23:59');
    });

    test('time range prefers minutesBegin/minutesEnd', () {
      final booking = Booking(
        id: '1',
        startsAt: DateTime.utc(2026, 11, 23, 8),
        minutesBegin: 19 * 60,
        minutesEnd: 20 * 60,
      );
      expect(bookingTimeRange(clock, booking), '19:00–20:00');
    });

    test('time range falls back to the absolute start', () {
      final booking = Booking(
        id: '1',
        startsAt: DateTime.parse('2026-11-23T19:00:00+07:00'),
      );
      expect(bookingTimeRange(clock, booking), '19:00');
    });

    test('end minutes still extend the range without minutesBegin', () {
      final booking = Booking(
        id: '1',
        startsAt: DateTime.parse('2026-11-23T19:00:00+07:00'),
        minutesEnd: 21 * 60,
      );
      expect(bookingTimeRange(clock, booking), '19:00–21:00');
    });

    test('undated booking has no time', () {
      expect(bookingTimeRange(clock, Booking(id: '1')), 'Время уточняется');
    });
  });

  group('card labels', () {
    test('rent uses the hall as title and the type as caption', () {
      final booking = Booking(
        id: '1',
        type: 2,
        hallName: 'Средний зал',
        branchName: "D'arky Dance · Главный",
      );
      expect(bookingCaption(booking), 'Аренда зала');
      expect(bookingTitle(booking), 'Средний зал');
      expect(bookingBranch(booking), "D'arky Dance · Главный");
    });

    test('individual falls back to its type when there is no hall', () {
      final booking = Booking(id: '1', type: 1);
      expect(bookingCaption(booking), 'Индивидуальное занятие');
      expect(bookingTitle(booking), 'Индивидуальное занятие');
      expect(bookingBranch(booking), isNull);
    });

    test('group uses the group name and the hall', () {
      final booking = Booking(
        id: '1',
        type: 0,
        title: 'Бачата Beginner',
        hallName: 'Большой зал',
      );
      expect(bookingCaption(booking), 'Бачата Beginner');
      expect(bookingTitle(booking), 'Большой зал');
    });

    test('blank fields are treated as missing', () {
      final booking = Booking(id: '1', hallName: '  ', branchName: '');
      expect(bookingBranch(booking), isNull);
      expect(bookingTitle(booking), 'Занятие');
    });
  });

  group('error messages', () {
    test('known failures get human wording', () {
      expect(
        bookingsErrorMessage(const NetworkFailure()),
        'Нет соединения с интернетом',
      );
      expect(
        bookingsErrorMessage(const TimeoutFailure()),
        'Сервер долго не отвечает',
      );
      expect(
        bookingsErrorMessage(const UnauthorizedFailure()),
        'Сессия истекла, войдите снова',
      );
      expect(
        bookingsErrorMessage(const VendorFailure('Внутренняя ошибка 500')),
        'Сервис клуба временно недоступен',
      );
    });

    test('unknown errors never expose internals', () {
      expect(
        bookingsErrorMessage(const UnknownFailure('DioException ...')),
        'Проверьте соединение и попробуйте снова',
      );
      expect(
        bookingsErrorMessage(StateError('boom')),
        'Проверьте соединение и попробуйте снова',
      );
    });
  });
}
