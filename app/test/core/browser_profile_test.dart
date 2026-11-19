import 'dart:ui' show Locale;

import 'package:dance/core/browser/browser_profile.dart';
import 'package:dance/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = AppConfig.defaults;

  test('builds the L2 Chrome profile for 156', () {
    final profile = BrowserProfile.create(
      chromeMajor: 156,
      config: config,
      locales: const [Locale('ru', 'RU'), Locale('en', 'US')],
    );

    expect(profile.userAgent, contains('Chrome/156.0.0.0'));
    expect(profile.userAgent, contains('Mobile Safari/537.36'));
    expect(profile.userAgent, isNot(contains('wv')));
    expect(
      profile.acceptLanguage,
      'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
    );
    expect(profile.headers['Accept'], 'application/json, text/plain, */*');
    expect(profile.headers['Accept-Encoding'], 'gzip, deflate, br, zstd');
    expect(profile.headers['Origin'], config.origin);
    expect(profile.headers['Referer'], '${config.baseUrl}/widget/2');
    expect(profile.headers['Sec-Fetch-Site'], 'same-origin');
    expect(profile.headers['Sec-Fetch-Mode'], 'cors');
    expect(profile.headers['Sec-Fetch-Dest'], 'empty');
    expect(profile.headers['Priority'], 'u=1, i');
    expect(profile.headers['Sec-CH-UA-Mobile'], '?1');
    expect(profile.headers['Sec-CH-UA-Platform'], '"Android"');
    expect(profile.headers['Sec-CH-UA'], contains('Chrome";v="156'));
    expect(profile.headers.containsKey('Cookie'), isFalse);
    expect(profile.headers.containsKey('X-Requested-With'), isFalse);
  });

  test('omits Client Hints for an unknown Chrome major', () {
    final profile = BrowserProfile.create(
      chromeMajor: 124,
      config: config,
      locales: const [Locale('ru', 'RU')],
    );

    expect(profile.userAgent, contains('Chrome/124.0.0.0'));
    expect(profile.headers.containsKey('Sec-CH-UA'), isFalse);
    expect(profile.headers.containsKey('Sec-CH-UA-Mobile'), isFalse);
    expect(profile.headers.containsKey('Sec-CH-UA-Platform'), isFalse);
  });

  test('locale header falls back to Russian', () {
    expect(LocaleHeader.build(const []), LocaleHeader.fallback);
  });
}
