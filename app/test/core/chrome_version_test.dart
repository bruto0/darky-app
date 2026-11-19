import 'package:dance/core/browser/chrome_version.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ru.darky.dance/browser');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('parses Chrome version names', () {
    expect(parseChromeMajor('156.0.8078.80'), 156);
    expect(parseChromeMajor('124.0.6367.219'), 124);
    expect(parseChromeMajor('156'), 156);
    expect(parseChromeMajor(''), isNull);
    expect(parseChromeMajor(null), isNull);
    expect(parseChromeMajor('Chrome/156.0'), isNull);
  });

  test('prefers installed Chrome over WebView', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getBrowserInfo');
      return <String, Object?>{
        'chromeVersion': '156.0.8078.80',
        'webviewVersion': '124.0.6367.219',
      };
    });

    final result = await PlatformChromeVersionProvider(
      channel: channel,
      fallbackMajor: 100,
    ).detect();

    expect(result.major, 156);
    expect(result.source, ChromeVersionSource.chrome);
  });

  test('falls back to WebView when Chrome is absent', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return <String, Object?>{
        'chromeVersion': null,
        'webviewVersion': '124.0.6367.219',
      };
    });

    final result = await PlatformChromeVersionProvider(
      channel: channel,
      fallbackMajor: 100,
    ).detect();

    expect(result.major, 124);
    expect(result.source, ChromeVersionSource.webview);
  });

  test('uses configured fallback when both are absent', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return <String, Object?>{'chromeVersion': null, 'webviewVersion': null};
    });

    final result = await PlatformChromeVersionProvider(
      channel: channel,
      fallbackMajor: 156,
    ).detect();

    expect(result.major, 156);
    expect(result.source, ChromeVersionSource.fallback);
  });
}
