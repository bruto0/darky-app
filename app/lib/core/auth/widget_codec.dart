import 'dart:convert';

/// Reversible widget encoding/obfuscation.
///
/// This is *not* encryption: the phone is recoverable, and the `secret` is
/// issued by the vendor. The codec exists only because the widget protocol
/// requires it.
class WidgetCodec {
  const WidgetCodec();

  static const int _phoneSalt = 49680531;
  static const String _xorKey = 'x7K2mQ9pL4';
  static const String _split = '2RnZGYNCmdmZGdkZg0KZ2ZkDQpn';

  static String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    } else if (digits.length == 10) {
      digits = '7$digits';
    }
    if (digits.length < 11 || digits.length > 15) {
      throw const FormatException('Некорректный номер телефона');
    }
    return digits;
  }

  String encodePhone(String phone) {
    final digits = normalizePhone(phone);
    final n = int.parse(digits) + _phoneSalt;
    final base36 = n.toRadixString(36);
    final reversed = base36.split('').reversed.join();
    return base64.encode(ascii.encode(reversed));
  }

  /// Decodes an obfuscated auth response into a JSON object.
  ///
  /// Vendor responses are base64 of JSON, optionally JSON-encoded twice.
  Map<String, dynamic> decodePayload(String payload) {
    final reversed = payload.split('').reversed.toList();
    final xored = String.fromCharCodes([
      for (var i = 0; i < reversed.length; i++)
        reversed[i].codeUnitAt(0) ^ _xorKey.codeUnitAt(i % _xorKey.length),
    ]);
    final parts = xored.split(_split);
    if (parts.length < 2) {
      throw const FormatException('Неожиданный формат ответа');
    }
    final encoded = (parts[0] + parts[1]).split('').reversed.join();
    final text = utf8.decode(base64.decode(encoded));
    dynamic value = jsonDecode(text);
    for (var i = 0; i < 2 && value is String; i++) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        break;
      }
    }
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Ответ не является JSON-объектом');
  }

  /// Reads `localStorage.impulsecrm_active`.
  ///
  /// The value is base64 of a JSON string (usually a phone), but tolerate a
  /// JSON object or a plain phone for older widget builds.
  static String? decodeActivePhone(Object? raw) {
    if (raw == null) return null;
    if (raw is Map) return _phoneFromJson(raw);
    if (raw is! String) return null;

    var value = raw.trim();
    if (value.isEmpty || value == 'null') return null;
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is String) value = decoded;
      } on FormatException {
        value = value.substring(1, value.length - 1);
      }
    }

    try {
      final bytes = base64.decode(base64.normalize(value));
      final text = utf8.decode(bytes);
      dynamic json;
      try {
        json = jsonDecode(text);
      } on FormatException {
        json = text;
      }
      final phone = _phoneFromJson(json);
      if (phone != null) return phone;
    } on FormatException {
      // Not base64: fall through to a plain phone.
    }

    try {
      return normalizePhone(value);
    } on FormatException {
      return null;
    }
  }

  static String? _phoneFromJson(Object? json) {
    if (json is String) {
      try {
        return normalizePhone(json);
      } on FormatException {
        return null;
      }
    }
    if (json is Map) {
      final value = json['phone'] ?? json['value'] ?? json['active'];
      if (value is String) {
        try {
          return normalizePhone(value);
        } on FormatException {
          return null;
        }
      }
    }
    return null;
  }
}
