import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// Where the Chrome major used for the HTTP profile came from.
enum ChromeVersionSource { chrome, webview, fallback }

class ChromeVersion {
  const ChromeVersion({
    required this.major,
    required this.source,
    this.rawVersion,
  });

  final int major;
  final ChromeVersionSource source;
  final String? rawVersion;

  String get sourceLabel => switch (source) {
        ChromeVersionSource.chrome => 'chrome',
        ChromeVersionSource.webview => 'webview',
        ChromeVersionSource.fallback => 'fallback',
      };
}

/// Parses `156.0.8078.80` (or `156`) into `156`.
int? parseChromeMajor(String? version) {
  if (version == null) return null;
  final match = RegExp(r'^(\d{1,3})').firstMatch(version.trim());
  if (match == null) return null;
  final major = int.tryParse(match.group(1)!);
  if (major == null || major < 1 || major > 999) return null;
  return major;
}

abstract class ChromeVersionProvider {
  Future<ChromeVersion> detect();
}

/// Asks Android for the installed Chrome and WebView versions.
///
/// Package visibility is declared in AndroidManifest.xml via `<queries>`.
class PlatformChromeVersionProvider implements ChromeVersionProvider {
  PlatformChromeVersionProvider({
    MethodChannel? channel,
    required this.fallbackMajor,
  }) : _channel = channel ?? const MethodChannel('ru.darky.dance/browser');

  final MethodChannel _channel;
  final int fallbackMajor;

  @override
  Future<ChromeVersion> detect() async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>(
        'getBrowserInfo',
      );
      final chromeRaw = info?['chromeVersion'] as String?;
      final chromeMajor = parseChromeMajor(chromeRaw);
      if (chromeMajor != null) {
        return ChromeVersion(
          major: chromeMajor,
          source: ChromeVersionSource.chrome,
          rawVersion: chromeRaw,
        );
      }
      final webViewRaw = info?['webviewVersion'] as String?;
      final webViewMajor = parseChromeMajor(webViewRaw);
      if (webViewMajor != null) {
        return ChromeVersion(
          major: webViewMajor,
          source: ChromeVersionSource.webview,
          rawVersion: webViewRaw,
        );
      }
    } on MissingPluginException {
      // Unit tests / desktop: use the configured fallback.
    } on PlatformException catch (error) {
      AppLogger.instance.w('Chrome version channel failed: ${error.code}');
    } catch (error) {
      AppLogger.instance.w('Chrome version detection failed: $error');
    }
    return ChromeVersion(
      major: fallbackMajor,
      source: ChromeVersionSource.fallback,
    );
  }
}

class FixedChromeVersionProvider implements ChromeVersionProvider {
  const FixedChromeVersionProvider(this.version);

  final ChromeVersion version;

  @override
  Future<ChromeVersion> detect() async => version;
}
