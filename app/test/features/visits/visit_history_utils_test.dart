import 'dart:ui' show Color;

import 'package:dance/core/models/visit.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/time/branch_clock.dart';
import 'package:dance/features/visits/visit_history_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Visit buildVisit({
  required String id,
  String? title,
  String? targetName,
  String? teacherName,
  List<String>? teacherNames,
  DateTime? visitedAt,
  int? serviceNumber,
  String? branchName,
  String? hallName,
  bool? byAccount,
  String? styleColor,
}) {
  return Visit(
    id: id,
    title: title,
    targetName: targetName,
    teacherName: teacherName,
    teacherNames: teacherNames,
    visitedAt: visitedAt,
    serviceNumber: serviceNumber,
    branchName: branchName,
    hallName: hallName,
    byAccount: byAccount,
    styleColor: styleColor,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  group('dedupeVisits', () {
    test('removes duplicates across page boundaries and keeps page order', () {
      final first = buildVisit(id: '2001', title: 'Бачата');
      final second = buildVisit(id: '2002', title: 'Сальса');
      final repeated = buildVisit(id: '2001', title: 'Бачата (дубль)');

      final result = dedupeVisits([first, second, repeated]);

      expect(result, [first, second]);
      expect(result.first.title, 'Бачата');
    });

    test('keeps visits with an empty id instead of collapsing them', () {
      final result = dedupeVisits([
        buildVisit(id: ''),
        buildVisit(id: ''),
        buildVisit(id: '7'),
      ]);

      expect(result, hasLength(3));
    });

    test('returns an empty list for empty input', () {
      expect(dedupeVisits(const []), isEmpty);
    });
  });

  group('formatVisitsCount', () {
    test('uses Russian plural forms', () {
      expect(formatVisitsCount(0), '0 посещений');
      expect(formatVisitsCount(1), '1 посещение');
      expect(formatVisitsCount(2), '2 посещения');
      expect(formatVisitsCount(4), '4 посещения');
      expect(formatVisitsCount(5), '5 посещений');
      expect(formatVisitsCount(11), '11 посещений');
      expect(formatVisitsCount(21), '21 посещение');
      expect(formatVisitsCount(89), '89 посещений');
    });
  });

  group('visitDateLabel', () {
    final clock = BranchClock(offset: const Duration(hours: 7));

    test('formats the branch date, not the device date', () {
      // 18:30 UTC is 01:30 of the next day in the UTC+7 branch.
      final visit = buildVisit(
        id: '1',
        visitedAt: DateTime.utc(2026, 11, 17, 18, 30),
      );

      expect(visitDateLabel(clock, visit), '18.11.2026');
    });

    test('keeps the same day when UTC and branch dates agree', () {
      final visit = buildVisit(
        id: '1',
        visitedAt: DateTime.utc(2026, 11, 17, 9),
      );

      expect(visitDateLabel(clock, visit), '17.11.2026');
    });

    test('returns a dash for a missing date', () {
      expect(visitDateLabel(clock, buildVisit(id: '1')), '—');
    });
  });

  group('visitServiceLabel', () {
    test('account visit with a service number', () {
      expect(
        visitServiceLabel(
          buildVisit(id: '1', byAccount: true, serviceNumber: 514),
        ),
        'Абонемент № 514',
      );
    });

    test('account visit without a service number', () {
      expect(
        visitServiceLabel(buildVisit(id: '1', byAccount: true)),
        'Абонемент',
      );
    });

    test('single visit', () {
      expect(
        visitServiceLabel(buildVisit(id: '1', byAccount: false)),
        'Разовое занятие',
      );
    });

    test('infers an account visit when byAccount is missing', () {
      expect(
        visitServiceLabel(buildVisit(id: '1', serviceNumber: 381)),
        'Абонемент № 381',
      );
    });
  });

  group('visitTitle', () {
    test('prefers title, then targetName, then a fallback', () {
      expect(visitTitle(buildVisit(id: '1', title: 'Бачата')), 'Бачата');
      expect(
        visitTitle(buildVisit(id: '1', title: '  ', targetName: 'Сальса')),
        'Сальса',
      );
      expect(visitTitle(buildVisit(id: '1')), 'Занятие');
    });
  });

  group('visitTeachers', () {
    test('joins teacherNames', () {
      expect(
        visitTeachers(
          buildVisit(
            id: '1',
            teacherNames: const ['Кальдерон Диего', 'Губина Наталья'],
          ),
        ),
        'Кальдерон Диего, Губина Наталья',
      );
    });

    test('falls back to a single teacherName', () {
      expect(
        visitTeachers(buildVisit(id: '1', teacherName: 'Мария')),
        'Мария',
      );
    });

    test('returns null when there are no teachers', () {
      expect(visitTeachers(buildVisit(id: '1')), isNull);
    });
  });

  group('visitBranchName', () {
    test('returns the branch', () {
      expect(
        visitBranchName(buildVisit(id: '1', branchName: 'Главный')),
        'Главный',
      );
    });

    test('does not substitute the hall for a missing branch', () {
      expect(
        visitBranchName(buildVisit(id: '1', hallName: 'Зал 1')),
        isNull,
      );
    });
  });

  group('style color', () {
    test('parses vendor hex formats', () {
      expect(parseColorHex('#C27BA0'), const Color(0xFFC27BA0));
      expect(parseColorHex('C27BA0'), const Color(0xFFC27BA0));
      expect(parseColorHex('#ABC'), const Color(0xFFAABBCC));
      expect(parseColorHex('0xFFC27BA0'), const Color(0xFFC27BA0));
    });

    test('returns null for missing or invalid values', () {
      expect(parseColorHex(null), isNull);
      expect(parseColorHex(''), isNull);
      expect(parseColorHex('не цвет'), isNull);
      expect(parseColorHex('#12'), isNull);
    });

    test('reads styleColor from the visit', () {
      expect(
        visitStyleColor(buildVisit(id: '1', styleColor: '2E9E9E')),
        const Color(0xFF2E9E9E),
      );
      expect(visitStyleColor(buildVisit(id: '1')), isNull);
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
        historyErrorText(const VendorFailure('Internal error')),
        contains('Сервис клуба'),
      );
    });

    test('never exposes a technical message', () {
      final message = historyErrorText(StateError('secret=abc'));

      expect(message, isNot(contains('secret')));
      expect(message, isNot(contains('StateError')));
    });
  });
}
