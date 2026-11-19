import 'dart:convert';

import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

sealed class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiFailure.fromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401) {
      return UnauthorizedFailure(statusCode: status);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return TimeoutFailure(statusCode: status);
    }
    if (error.type == DioExceptionType.connectionError) {
      return NetworkFailure(statusCode: status);
    }
    if (error.type == DioExceptionType.cancel) {
      return const CancelledFailure();
    }
    if (status != null) {
      final message = _vendorMessage(error.response?.data) ??
          _bytesMessage(error.response?.data) ??
          'Сервер вернул ошибку $status';
      if (message.toLowerCase().contains('validatesecret') ||
          message.toLowerCase().contains('logicexception')) {
        return UnauthorizedFailure(statusCode: status);
      }
      return VendorFailure(
        message,
        statusCode: status,
      );
    }
    return UnknownFailure(
      AppLogger.redact(error.message ?? 'Неизвестная сетевая ошибка'),
    );
  }

  static String? _vendorMessage(Object? data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty && data.length < 300) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          final message = decoded['message'] ?? decoded['error'];
          if (message is String && message.isNotEmpty) return message;
        }
      } on FormatException {
        return data;
      }
    }
    return null;
  }

  static String? _bytesMessage(Object? data) {
    if (data is! List<int>) return null;
    try {
      return _vendorMessage(utf8.decode(data));
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure({super.statusCode}) : super('Нет соединения с интернетом');
}

class TimeoutFailure extends ApiFailure {
  const TimeoutFailure({super.statusCode}) : super('Сервер долго не отвечает');
}

class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure({super.statusCode}) : super('Сессия истекла');
}

class VendorFailure extends ApiFailure {
  const VendorFailure(super.message, {super.statusCode});
}

class ParseFailure extends ApiFailure {
  const ParseFailure([super.message = 'Не удалось разобрать ответ сервера']);
}

class CompressionFailure extends ApiFailure {
  const CompressionFailure(super.message);
}

class CancelledFailure extends ApiFailure {
  const CancelledFailure() : super('Запрос отменён');
}

class UnknownFailure extends ApiFailure {
  const UnknownFailure(super.message);
}
