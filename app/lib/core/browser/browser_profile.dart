import 'dart:ui' show Locale, PlatformDispatcher;

import '../config/app_config.dart';

/// Low-entropy Client Hints for the current Chrome major.
///
/// Chrome sends a GREASE brand whose name/version changes between majors.
/// We only send hints for majors we have verified. For an unknown major it is
/// safer to omit `Sec-CH-UA` entirely than to claim a wrong brand.
class ChromeHints {
  const ChromeHints._();

  static Map<String, String> forMajor(int major) {
    if (major == 156) {
      return const {
        'Sec-CH-UA':
            '"Not:A-Brand";v="8", "Chromium";v="156", "Google Chrome";v="156"',
        'Sec-CH-UA-Mobile': '?1',
        'Sec-CH-UA-Platform': '"Android"',
      };
    }
    return const {};
  }
}

/// Builds Chrome's `Accept-Language` shape from device locales.
class LocaleHeader {
  const LocaleHeader._();

  static const fallback =
      'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7';

  static String build(List<Locale> locales) {
    if (locales.isEmpty) return fallback;

    final values = <String>[];
    final seen = <String>{};
    var quality = 1.0;

    void add(String value, {bool withQuality = true}) {
      final normalized = value.toLowerCase();
      if (normalized.isEmpty || !seen.add(normalized)) return;
      if (withQuality && quality < 0.999) {
        values.add('$value;q=${quality.toStringAsFixed(1)}');
      } else {
        values.add(value);
      }
      quality = (quality - 0.1).clamp(0.1, 1.0);
    }

    for (final locale in locales.take(3)) {
      final tag = locale.toLanguageTag();
      if (tag.isEmpty) continue;
      add(tag, withQuality: values.isNotEmpty);
      if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
        add(locale.languageCode);
      }
      if (values.length >= 6) break;
    }

    return values.isEmpty ? fallback : values.join(',');
  }
}

/// Immutable browser identity used by the native HTTP client and the WebView.
class BrowserProfile {
  const BrowserProfile({
    required this.chromeMajor,
    required this.userAgent,
    required this.acceptLanguage,
    required this.clientHints,
    required this.origin,
    required this.referer,
  });

  factory BrowserProfile.create({
    required int chromeMajor,
    required AppConfig config,
    List<Locale>? locales,
  }) {
    return BrowserProfile(
      chromeMajor: chromeMajor,
      userAgent: userAgentFor(chromeMajor),
      acceptLanguage: LocaleHeader.build(
        locales ?? PlatformDispatcher.instance.locales,
      ),
      clientHints: ChromeHints.forMajor(chromeMajor),
      origin: config.origin,
      referer: config.referer,
    );
  }

  static String userAgentFor(int chromeMajor) {
    return 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/$chromeMajor.0.0.0 Mobile Safari/537.36';
  }

  /// The vendor widget's VK Bridge hangs with a mobile Android UA inside a
  /// WebView (it waits for the VK app). A desktop Chrome UA of the same major
  /// loads the regular web login; the native API still uses the mobile L2 UA.
  static String webViewUserAgentFor(int chromeMajor) {
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/$chromeMajor.0.0.0 Safari/537.36';
  }

  final int chromeMajor;
  final String userAgent;
  final String acceptLanguage;
  final Map<String, String> clientHints;
  final String origin;
  final String referer;

  static const acceptEncoding = 'gzip, deflate, br, zstd';

  Map<String, String> get headers {
    final result = <String, String>{};
    result.addAll(clientHints);
    result
      ..['User-Agent'] = userAgent
      ..['Accept'] = 'application/json, text/plain, */*'
      ..['Accept-Language'] = acceptLanguage
      ..['Content-Type'] = 'application/json'
      ..['Origin'] = origin
      ..['Referer'] = referer
      ..['Sec-Fetch-Site'] = 'same-origin'
      ..['Sec-Fetch-Mode'] = 'cors'
      ..['Sec-Fetch-Dest'] = 'empty'
      ..['Priority'] = 'u=1, i'
      ..['Accept-Encoding'] = acceptEncoding;
    return result;
  }
}
