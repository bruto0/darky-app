import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:brotli_fast/brotli_fast.dart';
import 'package:dance/core/browser/browser_profile.dart';
import 'package:dance/core/config/app_config.dart';
import 'package:dance/core/network/api_client.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_zstd/just_zstd.dart';

void main() {
  late HttpServer server;
  late ApiClient client;
  late List<Map<String, String>> requestHeaders;

  setUpAll(() async {
    requestHeaders = [];
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
    client = ApiClient(profile: profile, config: config);

    server.listen((request) async {
      final headerMap = <String, String>{};
      request.headers.forEach((name, values) {
        headerMap[name.toLowerCase()] = values.join(',');
      });
      requestHeaders.add(headerMap);
      final raw = utf8.encode('{"ok":true,"path":"${request.uri.path}"}');
      late final List<int> body;
      late final String encoding;
      switch (request.uri.path) {
        case '/gzip':
          body = gzip.encode(raw);
          encoding = 'gzip';
        case '/deflate':
          body = zlib.encode(raw);
          encoding = 'deflate';
        case '/br':
          body = brotliEncode(raw);
          encoding = 'br';
        case '/zstd':
          body = ZstdEncoder().encode(raw);
          encoding = 'zstd';
        case '/unknown':
          body = raw;
          encoding = 'made-up';
        default:
          body = raw;
          encoding = 'identity';
      }
      request.response.headers.contentType = ContentType.json;
      request.response.headers.set('Content-Encoding', encoding);
      request.response.add(body);
      await request.response.close();
    });
  });

  tearDownAll(() async {
    client.close(force: true);
    await server.close(force: true);
  });

  test('sends the L2 profile and decodes gzip', () async {
    final result = await client.post('/gzip', {'x': 1});
    expect(result['ok'], isTrue);

    final headers = requestHeaders.last;
    expect(headers['user-agent'], contains('Chrome/156.0.0.0'));
    expect(headers['user-agent'], isNot(contains('wv')));
    expect(headers['accept-encoding'], 'gzip, deflate, br, zstd');
    expect(headers['sec-ch-ua'], contains('Chrome";v="156'));
    expect(headers['sec-ch-ua-mobile'], '?1');
    expect(headers['sec-ch-ua-platform'], '"Android"');
    expect(headers['origin'], 'http://127.0.0.1:${server.port}');
    expect(headers['referer'], 'http://127.0.0.1:${server.port}/widget/2');
    expect(headers.containsKey('cookie'), isFalse);
  });

  test('decodes deflate, brotli and zstd', () async {
    for (final path in ['/deflate', '/br', '/zstd']) {
      final result = await client.post(path, {'x': 1});
      expect(result['ok'], isTrue, reason: path);
      expect(result['path'], path);
    }
  });

  test('maps unsupported compression to a failure', () async {
    await expectLater(
      client.post('/unknown', {'x': 1}),
      throwsA(isA<CompressionFailure>()),
    );
  });
}
