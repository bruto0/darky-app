import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:dance/core/auth/auth_failure.dart';
import 'package:dance/core/auth/auth_repository.dart';
import 'package:dance/core/browser/browser_profile.dart';
import 'package:dance/core/config/app_config.dart';
import 'package:dance/core/network/api_client.dart';
import 'package:dance/core/storage/session.dart';
import 'package:dance/core/storage/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

const _xorKey = 'x7K2mQ9pL4';
const _split = '2RnZGYNCmdmZGdkZg0KZ2ZkDQpn';

String _encodePayload(Object value) {
  final base = base64.encode(utf8.encode(jsonEncode(value)));
  final reversed = base.split('').reversed.join();
  final at = reversed.length ~/ 2;
  final withSep = reversed.substring(0, at) + _split + reversed.substring(at);
  final xored = String.fromCharCodes([
    for (var i = 0; i < withSep.length; i++)
      withSep.codeUnitAt(i) ^ _xorKey.codeUnitAt(i % _xorKey.length),
  ]);
  return xored.split('').reversed.join();
}

class MemorySessionStore implements SessionStore {
  Session? value;

  @override
  Future<Session?> read() async => value;

  @override
  Future<void> write(Session session) async => value = session;

  @override
  Future<void> clear() async => value = null;
}

void main() {
  late HttpServer server;
  late ApiClient api;
  late MemorySessionStore store;
  late WidgetAuthRepository repository;
  late String requestBody;

  setUp(() async {
    requestBody = '';
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
    store = MemorySessionStore();
    repository = WidgetAuthRepository(api: api, store: store, config: config);

    server.listen((request) async {
      requestBody = await utf8.decoder.bind(request).join();
      final path = request.uri.path;
      Object data;
      if (path.endsWith('/phone_info')) {
        data = {'count': 1, 'ids': [255], 'hasPassword': 1};
      } else if (path.endsWith('/check_password')) {
        final body = jsonDecode(requestBody) as Map<String, dynamic>;
        data = {'success': body['password'] == 'fake-password'};
      } else {
        data = {
          'total': 1,
          'items': [
            {
              'id': 255,
              'name': 'Анна',
              'lastName': 'Смирнова',
              'branch': {'name': "D'arky Dance"},
              'secret': 'demo-secret',
            },
          ],
        };
      }
      final payload = _encodePayload(data);
      request.response.headers.contentType = ContentType(
        'text',
        'plain',
        charset: 'utf-8',
      );
      request.response.write(payload);
      await request.response.close();
    });
  });

  tearDown(() async {
    api.close(force: true);
    await server.close(force: true);
  });

  test('searches the widget and stores the session', () async {
    final session = await repository.completeLogin('+79001234567');

    expect(session.clientId, 255);
    expect(session.secret, 'demo-secret');
    expect(session.profile.fullName, 'Смирнова Анна');
    expect(store.value?.clientId, 255);

    final body = jsonDecode(requestBody) as Map<String, dynamic>;
    expect(body['phone'], 'cWdndmNiMDE=');
    expect(body['socialPage'], isNull);
  });

  test('native login checks the password and stores the session', () async {
    final session = await repository.completeNativeLogin(
      '+79001234567',
      'fake-password',
    );

    expect(session.clientId, 255);
    expect(session.secret, 'demo-secret');
    expect(store.value?.clientId, 255);
  });

  test('native login rejects a wrong password', () async {
    await expectLater(
      repository.completeNativeLogin('+79001234567', 'wrong'),
      throwsA(isA<AuthFailure>()),
    );
    expect(store.value, isNull);
  });
}
