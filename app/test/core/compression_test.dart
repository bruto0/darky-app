import 'dart:convert';
import 'dart:io';

import 'package:brotli_fast/brotli_fast.dart';
import 'package:dance/core/network/api_failure.dart';
import 'package:dance/core/network/compression.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_zstd/just_zstd.dart';

void main() {
  final raw = utf8.encode('{"ok":true,"text":"привет"}');

  test('decodes gzip and deflate', () {
    expect(
      utf8.decode(decodeResponseBody(gzip.encode(raw), 'gzip')),
      utf8.decode(raw),
    );
    expect(
      utf8.decode(decodeResponseBody(zlib.encode(raw), 'deflate')),
      utf8.decode(raw),
    );
  });

  test('decodes brotli and zstd', () {
    expect(
      utf8.decode(decodeResponseBody(brotliEncode(raw), 'br')),
      utf8.decode(raw),
    );
    expect(
      utf8.decode(
        decodeResponseBody(ZstdEncoder().encode(raw), 'zstd'),
      ),
      utf8.decode(raw),
    );
  });

  test('rejects unknown encoding', () {
    expect(
      () => decodeResponseBody(raw, 'made-up'),
      throwsA(isA<CompressionFailure>()),
    );
  });
}
