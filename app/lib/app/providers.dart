import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth/auth_repository.dart';
import '../core/auth/widget_codec.dart';
import '../core/browser/browser_profile.dart';
import '../core/browser/chrome_version.dart';
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/storage/json_cache.dart';
import '../core/storage/session.dart';
import '../core/storage/session_store.dart';
import '../core/time/branch_clock.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.defaults);

final chromeVersionProvider = Provider<ChromeVersionProvider>((ref) {
  final config = ref.watch(appConfigProvider);
  return PlatformChromeVersionProvider(fallbackMajor: config.defaultChromeMajor);
});

final widgetCodecProvider = Provider<WidgetCodec>((ref) => const WidgetCodec());

/// Overridden in bootstrap after Chrome/WebView version detection.
final browserProfileProvider = Provider<BrowserProfile>((ref) {
  throw UnimplementedError('BrowserProfile must be overridden at bootstrap');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    profile: ref.watch(browserProfileProvider),
    config: ref.watch(appConfigProvider),
  );
  ref.onDispose(() => client.close(force: true));
  return client;
});

final branchClockProvider = Provider<BranchClock>((ref) {
  final config = ref.watch(appConfigProvider);
  return BranchClock(
    offset: Duration(minutes: config.branchTimezoneOffsetMinutes),
  );
});

final jsonCacheProvider = Provider<JsonCache>((ref) {
  throw UnimplementedError('JsonCache must be overridden at bootstrap');
});

final sessionStoreProvider =
    Provider<SessionStore>((ref) => SecureSessionStore());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return WidgetAuthRepository(
    api: ref.watch(apiClientProvider),
    store: ref.watch(sessionStoreProvider),
    config: ref.watch(appConfigProvider),
    codec: ref.watch(widgetCodecProvider),
  );
});

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

class SessionController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    try {
      return await ref.read(authRepositoryProvider).restore();
    } catch (_) {
      return null;
    }
  }

  Future<void> completeLogin(String phone) async {
    final session = await ref.read(authRepositoryProvider).completeLogin(phone);
    state = AsyncData(session);
  }

  Future<void> completeNativeLogin(String phone, String password) async {
    final session =
        await ref.read(authRepositoryProvider).completeNativeLogin(phone, password);
    state = AsyncData(session);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

