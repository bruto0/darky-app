import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../browser/browser_profile.dart';
import '../config/app_config.dart';
import 'api_failure.dart';
import 'compression.dart';

/// Thin Dio wrapper with the L2 Chrome profile and compression handling.
///
/// The client is cookie-less on purpose: the widget API authenticates with
/// `client_id` + `secret` in the JSON body, not with a browser session.
class ApiClient {
  ApiClient({
    required this.profile,
    required this.config,
    Dio? dio,
  }) : _dio = dio ?? _createDio(profile, config) {
    if (dio != null) {
      dio.options.headers.addAll(profile.headers);
    }
  }

  final BrowserProfile profile;
  final AppConfig config;
  final Dio _dio;

  Dio get dio => _dio;

  static Dio _createDio(BrowserProfile profile, AppConfig config) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.bytes,
        headers: profile.headers,
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // We decode gzip/br/zstd ourselves, so keep the wire bytes.
        client.autoUncompress = false;
        return client;
      },
    );
    return dio;
  }

  Future<String> postText(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _readText(
      () => _dio.post<List<int>>(
        path,
        data: body,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
  }

  Future<String> getText(String path) async {
    return _readText(
      () => _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
  }

  Future<String> _readText(Future<Response<List<int>>> Function() request) async {
    try {
      final response = await request();
      final bytes = response.data ?? const <int>[];
      final decoded = decodeResponseBody(
        bytes,
        response.headers.value(Headers.contentEncodingHeader),
      );
      return utf8.decode(decoded);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ParseFailure();
    } catch (error) {
      throw UnknownFailure('Ошибка запроса: $error');
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final text = await postText(path, body);
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
      throw const ParseFailure('Ответ не является JSON-объектом');
    } on FormatException {
      throw const ParseFailure();
    }
  }

  void close({bool force = false}) => _dio.close(force: force);
}
