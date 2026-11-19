import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Small on-disk JSON cache for stale-while-revalidate screens.
class JsonCache {
  JsonCache(this.directory);

  static Future<JsonCache> create() async {
    return JsonCache(await getTemporaryDirectory());
  }

  final Directory directory;

  Future<File> _file(String key) async {
    final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File('${directory.path}${Platform.pathSeparator}cache_$safe.json');
  }

  Future<Map<String, dynamic>?> read(
    String key, {
    Duration ttl = const Duration(hours: 6),
  }) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final stat = await file.stat();
      if (DateTime.now().difference(stat.modified) > ttl) {
        await file.delete();
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> value) async {
    final file = await _file(key);
    await directory.create(recursive: true);
    await file.writeAsString(jsonEncode(value), flush: true);
  }

  Future<void> clear() async {
    if (!await directory.exists()) return;
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.contains('cache_')) {
        await entity.delete();
      }
    }
  }
}
