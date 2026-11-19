import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:dance/core/browser/browser_profile.dart';
import 'package:dance/core/config/app_config.dart';
import 'package:dance/core/data/widget_lk_repository.dart';
import 'package:dance/core/network/api_client.dart';
import 'package:dance/core/storage/session.dart';
import 'package:dance/core/time/branch_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late ApiClient api;
  late WidgetLkRepository repository;
  late String lastPath;
  late Map<String, dynamic> lastBody;

  final session = Session(
    clientId: 255,
    secret: 'demo-secret',
    profile: const ClientProfile(id: 255, firstName: 'Анна', lastName: 'Смирнова'),
    createdAt: DateTime.utc(2026, 11, 20),
  );

  setUp(() async {
    lastPath = '';
    lastBody = {};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final config = AppConfig(
      baseUrl: 'http://127.0.0.1:${server.port}',
      widgetId: 2,
      branchId: 1,
      branchTimezoneOffsetMinutes: 420,
      defaultChromeMajor: 156,
      appVersion: 'test',
    );
    final profile = BrowserProfile.create(
      chromeMajor: 156,
      config: config,
      locales: const [Locale('ru', 'RU')],
    );
    api = ApiClient(profile: profile, config: config);
    repository = WidgetLkRepository(
      api: api,
      config: config,
      clock: BranchClock(now: () => DateTime.utc(2026, 11, 19, 5)),
    );

    server.listen((request) async {
      lastPath = request.uri.path;
      lastBody = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      final path = request.uri.path;
      Object payload;
      if (path.endsWith('/accounts')) {
        payload = {
          'total': 1,
          'items': [
            {
              'id': 514,
              'typeName': 'ПРОФИ',
              'trainings': 24,
              'trainingsUsed': 4,
              'freezeEnable': true,
              'freezeDaysLeft': 21,
              'freezeDaysTotal': 21,
              'validUntil': 1791417600,
            },
          ],
        };
      } else if (path.endsWith('/widget_schedule/list')) {
        payload = {
          'total': 2,
          'items': [
            {
              'id': 1,
              'type': 1,
              'minutesBegin': 600,
              'minutesEnd': 660,
              'hall': {'name': 'Средний'},
              'teacher': {'name': 'Андрей', 'lastName': 'Чистяков'},
              'client': {'id': 255, 'name': 'Анна', 'lastName': 'Смирнова'},
            },
            {
              'id': 2,
              'type': 1,
              'minutesBegin': 700,
              'minutesEnd': 760,
              'hall': {'name': 'Малый'},
              'client': {'id': 999, 'name': 'Другой', 'lastName': 'Клиент'},
            },
          ],
        };
      } else if (path.endsWith('/visits')) {
        payload = {
          'total': 89,
          'items': [
            {
              'id': 1,
              'visitDate': 1790000000,
              'target': {'name': 'Бачата'},
              'service': 514,
            },
          ],
        };
      } else if (path.endsWith('/deposits')) {
        payload = {
          'total': 18,
          'items': [
            {
              'id': 1,
              'typeText': 'пополнение счета',
              'sum': 5000,
              'created': 1790000000,
            },
          ],
        };
      } else if (path.endsWith('/schedule') &&
          path.contains('widget_client_lk')) {        payload = {
          'total': 1,
          'items': [
            {
              'id': 1,
              'type': 2,
              'minutesBegin': 600,
              'minutesEnd': 660,
              'hall': {'name': 'Зал 1'},
              'date': 1795000000,
            },
          ],
        };
      } else if (path.endsWith('/barcode')) {
        payload = {'barcode': base64Encode([1, 2, 3])};
      } else {
        payload = {'total': 0, 'items': []};
      }
      request.response.headers.contentType = ContentType(
        'application',
        'json',
        charset: 'utf-8',
      );
      request.response.write(jsonEncode(payload));
      await request.response.close();
    });
  });

  tearDown(() async {
    api.close(force: true);
    await server.close(force: true);
  });

  test('loads accounts with client credentials', () async {
    final accounts = await repository.accounts(session);

    expect(accounts, hasLength(1));
    expect(accounts.first.typeName, 'ПРОФИ');
    expect(accounts.first.visitsLeft, 20);
    expect(accounts.first.freezeAvailable, isTrue);
    expect(lastPath, '/api/public/widget_client_lk/accounts');
    expect(lastBody['filters'], {
      'client_id': 255,
      'secret': 'demo-secret',
    });
  });

  test('loads the public day schedule and marks the client items', () async {
    final items = await repository.schedule(session, DateTime(2026, 11, 19));

    expect(items, hasLength(2));
    expect(items.first.minutesBegin, 600);
    expect(items.first.teacherName, 'Андрей Чистяков');
    expect(items.first.isMine, isTrue);
    expect(items.last.isMine, isFalse);
    expect(lastPath, '/api/public/widget_schedule/list');
    final range = lastBody['range'] as Map;
    // 2026-11-19 00:00 UTC+7 == 2026-11-18 17:00 UTC.
    expect(range['from'], 1795021200);
    expect(range['to'], 1795021200);
    expect(lastBody['filters']['individuals'], isTrue);
  });

  test('loads visits with mandatory sort and dedupe-ready paging', () async {
    final page = await repository.visits(session, 2);

    expect(page.total, 89);
    expect(page.items.single.serviceNumber, 514);
    expect(lastBody['sort'], {'visit_date': 'desc', 'created': 'desc'});
    expect(lastBody['page'], 2);
    expect(lastBody['filters']['client_id'], 255);
  });

  test('loads deposits with type filter', () async {
    final page = await repository.deposits(session, 1);

    expect(page.total, 18);
    expect(page.items.single.typeText, 'пополнение счета');
    expect(lastBody['filters']['type'], [11, 12, 13]);
  });

  test('loads personal bookings', () async {
    final items = await repository.bookings(session);

    expect(items, hasLength(1));
    expect(items.single.isRent, isTrue);
    expect(lastBody['filters']['secret'], 'demo-secret');
  });

  test('decodes barcode png', () async {
    final bytes = await repository.barcode(session);

    expect(bytes, [1, 2, 3]);
  });
}
