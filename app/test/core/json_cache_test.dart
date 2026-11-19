import 'dart:io';

import 'package:dance/core/storage/json_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late JsonCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('darky_cache_');
    cache = JsonCache(directory);
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('writes, reads and clears JSON', () async {
    await cache.write('accounts', {'total': 2});
    expect(await cache.read('accounts'), {'total': 2});
    await cache.clear();
    expect(await cache.read('accounts'), isNull);
  });

  test('returns null for missing keys', () async {
    expect(await cache.read('missing'), isNull);
  });
}
