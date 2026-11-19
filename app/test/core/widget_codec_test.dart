import 'dart:convert';

import 'package:dance/core/auth/widget_codec.dart';
import 'package:flutter_test/flutter_test.dart';

const _xorKey = 'x7K2mQ9pL4';
const _split = '2RnZGYNCmdmZGdkZg0KZ2ZkDQpn';

String _encodePayload(Object value) {
  final base = base64.encode(utf8.encode(jsonEncode(value)));
  final reversed = base.split('').reversed.join();
  final at = reversed.length ~/ 2;
  final withSep = reversed.substring(0, at) + _split + reversed.substring(at);
  final xored = String.fromCharCodes([
    for (var i = 0; i < withSep.length; i++)
      withSep.codeUnitAt(i) ^ _xorKey.codeUnitAt(i % _xorKey.length),
  ]);
  return xored.split('').reversed.join();
}

void main() {
  const codec = WidgetCodec();

  test('encodes the documented phone vector', () {
    expect(codec.encodePhone('+79001234567'), 'cWdndmNiMDE=');
    expect(codec.encodePhone('89001234567'), 'cWdndmNiMDE=');
    expect(codec.encodePhone('9001234567'), 'cWdndmNiMDE=');
  });

  test('decodes an auth payload', () {
    final payload = _encodePayload({
      'total': 1,
      'items': [
        {'id': 255, 'secret': 'demo', 'name': 'Анна'},
      ],
    });
    final decoded = codec.decodePayload(payload);
    expect(decoded['total'], 1);
    expect((decoded['items'] as List).single['secret'], 'demo');
  });

  test('decodes double-encoded JSON', () {
    final payload = _encodePayload(
      jsonEncode({'total': 1, 'items': []}),
    );
    expect(codec.decodePayload(payload)['total'], 1);
  });

  test('reads impulse active phone from localStorage shapes', () {
    final asString = base64.encode(
      utf8.encode(jsonEncode('79001234567')),
    );
    final asObject = base64.encode(
      utf8.encode(jsonEncode({'phone': '79001234567'})),
    );

    expect(WidgetCodec.decodeActivePhone(asString), '79001234567');
    expect(WidgetCodec.decodeActivePhone(asObject), '79001234567');
    expect(WidgetCodec.decodeActivePhone('"79001234567"'), '79001234567');
    expect(WidgetCodec.decodeActivePhone('79001234567'), '79001234567');
    expect(WidgetCodec.decodeActivePhone(null), isNull);
    expect(WidgetCodec.decodeActivePhone('null'), isNull);
  });

  test('normalizes ten-digit and leading-eight phones', () {
    expect(WidgetCodec.normalizePhone('9001234567'), '79001234567');
    expect(WidgetCodec.normalizePhone('89001234567'), '79001234567');
  });
}
