import 'dart:io';
import 'dart:typed_data';

import 'package:brotli_fast/brotli_fast.dart';
import 'package:just_zstd/just_zstd.dart';

import 'api_failure.dart';

/// Decodes a response body according to `Content-Encoding`.
///
/// `HttpClient.autoUncompress` is disabled in [ApiClient], so gzip arrives
/// untouched; br/zstd are decoded here. A 20 MiB cap protects against
/// decompression bombs.
Uint8List decodeResponseBody(
  List<int> bytes,
  String? contentEncoding, {
  int maxOutputSize = 20 << 20,
}) {
  final encoding = contentEncoding
      ?.split(',')
      .last
      .trim()
      .toLowerCase();

  if (encoding == null || encoding.isEmpty || encoding == 'identity') {
    return Uint8List.fromList(bytes);
  }

  try {
    return switch (encoding) {
      'gzip' || 'x-gzip' => Uint8List.fromList(gzip.decode(bytes)),
      'deflate' => Uint8List.fromList(zlib.decode(bytes)),
      'br' => brotliDecode(
          Uint8List.fromList(bytes),
          maxOutputSize: maxOutputSize,
        ),
      'zstd' => ZstdDecoder().decode(
          Uint8List.fromList(bytes),
          maxOutputSize: maxOutputSize,
        ),
      _ => throw CompressionFailure('Неизвестное сжатие: $encoding'),
    };
  } on CompressionFailure {
    rethrow;
  } on FormatException catch (error) {
    throw CompressionFailure('Не удалось распаковать $encoding: ${error.message}');
  } catch (error) {
    throw CompressionFailure('Не удалось распаковать $encoding: $error');
  }
}
