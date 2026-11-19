/// Static configuration for the D'arky client.
///
/// Secrets never live here: `client_id` and `secret` arrive at runtime from
/// the WebView login and are stored in the platform keystore.
class AppConfig {
  const AppConfig({
    required this.baseUrl,
    required this.widgetId,
    required this.branchId,
    required this.branchTimezoneOffsetMinutes,
    required this.defaultChromeMajor,
    required this.appVersion,
  });

  static const AppConfig defaults = AppConfig(
    baseUrl: 'https://4621c03198bd6735334088.impulsemini.ru',
    widgetId: 2,
    branchId: 1,
    branchTimezoneOffsetMinutes: 420,
    defaultChromeMajor: 156,
    appVersion: '1.0.0',
  );

  final String baseUrl;
  final int widgetId;
  final int branchId;
  final int branchTimezoneOffsetMinutes;

  /// Fallback only: the real major is read from the installed Chrome, then
  /// from the system WebView.
  final int defaultChromeMajor;
  final String appVersion;

  String get origin => Uri.parse(baseUrl).origin;
  String get referer => '$baseUrl/widget/$widgetId';
  String get widgetPath => '/widget/$widgetId';
  String get apiBasePath => '/api/public';

  Uri apiUri(String path) => Uri.parse('$baseUrl$apiBasePath/$path');
}
