import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/api_failure.dart';
import '../storage/session.dart';
import '../storage/session_store.dart';
import 'auth_failure.dart';
import 'widget_codec.dart';

abstract class AuthRepository {
  Future<Session?> restore();
  Future<Session> completeLogin(String phone);
  Future<Session> completeNativeLogin(String phone, String password);
  Future<void> logout();
}

class WidgetAuthRepository implements AuthRepository {
  WidgetAuthRepository({
    required this.api,
    required this.store,
    required this.config,
    this.codec = const WidgetCodec(),
  });

  final ApiClient api;
  final SessionStore store;
  final AppConfig config;
  final WidgetCodec codec;

  @override
  Future<Session?> restore() => store.read();

  @override
  Future<Session> completeLogin(String phone) async {
    return _search(codec.encodePhone(phone));
  }

  @override
  Future<Session> completeNativeLogin(String phone, String password) async {
    final encodedPhone = codec.encodePhone(phone);

    final infoBody = await api.postText(
      '${config.apiBasePath}/widget_schedule/phone_info',
      {'phone': encodedPhone},
    );
    final info = _decodeOrFail(infoBody);
    final count = (info['count'] as num?)?.toInt() ?? 0;
    if (count == 0) {
      throw const AuthFailure('Телефон не найден в клубе');
    }
    final hasPassword = (info['hasPassword'] as num?)?.toInt() ?? 0;
    if (hasPassword == 0) {
      throw const AuthFailure(
        'Для этого номера не задан пароль. Воспользуйтесь восстановлением.',
      );
    }

    final checkBody = await api.postText(
      '${config.apiBasePath}/widget_schedule/check_password',
      {'phone': encodedPhone, 'password': password},
    );
    final check = _decodeOrFail(checkBody);
    if (check['success'] != true) {
      throw const AuthFailure('Неверный пароль');
    }

    return _search(encodedPhone);
  }

  Future<Session> _search(String encodedPhone) async {
    final body = await api.postText(
      '${config.apiBasePath}/widget_client_lk/search',
      {'phone': encodedPhone, 'socialPage': null},
    );

    final decoded = _decodeOrFail(body);
    final items = decoded['items'];
    if (items is! List || items.isEmpty) {
      throw const AuthFailure('Клиент не найден');
    }
    final first = items.first;
    if (first is! Map) {
      throw const AuthFailure('Клиент не найден');
    }
    final item = Map<String, dynamic>.from(first);
    final id = (item['id'] as num?)?.toInt();
    final secret = item['secret'];
    if (id == null || secret is! String || secret.isEmpty) {
      throw const AuthFailure('Клуб не вернул данные сессии');
    }

    final session = Session(
      clientId: id,
      secret: secret,
      profile: ClientProfile.fromJson(item),
      createdAt: DateTime.now().toUtc(),
    );
    await store.write(session);
    return session;
  }

  Map<String, dynamic> _decodeOrFail(String body) {
    try {
      return codec.decodePayload(body);
    } on FormatException {
      throw const AuthFailure('Не удалось разобрать ответ клуба');
    }
  }

  @override
  Future<void> logout() => store.clear();
}

class AuthFailureMapper {
  const AuthFailureMapper._();

  static String message(Object error) {
    if (error is AuthFailure) return error.message;
    if (error is ApiFailure) return error.message;
    return 'Не удалось войти. Попробуйте ещё раз.';
  }
}
