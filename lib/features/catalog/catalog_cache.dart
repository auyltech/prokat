import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';

class CatalogCacheEntry {
  final CatalogBundle bundle;
  final DateTime fetchedAt;

  const CatalogCacheEntry({required this.bundle, required this.fetchedAt});
}

class CatalogCache {
  static const assetPath = 'assets/catalog/catalog_bundle.json';
  static const _fileName = 'catalog_bundle.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final catalogDir = Directory('${dir.path}${Platform.pathSeparator}catalog');
    if (!await catalogDir.exists()) {
      await catalogDir.create(recursive: true);
    }
    return File('${catalogDir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<CatalogCacheEntry?> readDisk() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final bundleJson = map['bundle'] is Map
          ? Map<String, dynamic>.from(map['bundle'] as Map)
          : map;
      final fetchedAt =
          DateTime.tryParse(map['fetchedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return CatalogCacheEntry(
        bundle: CatalogBundle.fromJson(bundleJson),
        fetchedAt: fetchedAt.toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<CatalogBundle> readAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Failed to load CatalogBundle.');
    }
    return CatalogBundle.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> write(CatalogBundle bundle, {DateTime? fetchedAt}) async {
    final file = await _file();
    final payload = jsonEncode({
      'fetchedAt': (fetchedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'bundle': bundle.toJson(),
    });
    await file.writeAsString(payload, flush: true);
  }
}
