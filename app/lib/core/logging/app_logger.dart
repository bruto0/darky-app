import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Central logger with mandatory redaction.
///
/// The app never logs phone numbers, secrets, client ids or names. Keep it
/// that way: use [redact] for every external string.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static final RegExp _phone = RegExp(
    r'(?<!\d)(?:\+7|8)?[\s\-()]*\d{3}[\s\-()]*\d{3}[\s\-()]*\d{2}[\s\-()]*\d{2}(?!\d)',
  );
  static final RegExp _secret = RegExp(r'\b[0-9a-fA-F]{64}\b');

  static String redact(String value) {
    return value.replaceAll(_phone, '+7***').replaceAll(_secret, '***');
  }

  void d(String message) {
    if (kDebugMode) {
      developer.log(redact(message), name: 'DARKY', level: 500);
    }
  }

  void w(String message) {
    developer.log(redact(message), name: 'DARKY', level: 900);
  }

  void e(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      redact(message),
      name: 'DARKY',
      level: 1000,
      error: error == null ? null : redact(error.toString()),
      stackTrace: stackTrace,
    );
  }
}
