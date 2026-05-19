import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationLocalStorage {
  static const _lastTokenKey = 'notifications_last_fcm_token';
  static const _lastTokenAtKey = 'notifications_last_fcm_token_at';
  static const _lastTokenUserIdKey = 'notifications_last_fcm_token_user_id';
  static const _pendingRouteKey = 'notifications_pending_route';

  final FlutterSecureStorage _storage;

  NotificationLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveLastRegisteredToken({
    required String token,
    required DateTime at,
    required String? userId,
  }) async {
    await _storage.write(key: _lastTokenKey, value: token);
    await _storage.write(key: _lastTokenAtKey, value: at.toIso8601String());
    await _storage.write(key: _lastTokenUserIdKey, value: userId ?? '');
  }

  Future<({String token, DateTime? at, String? userId})?> readLastRegisteredToken()
      async {
    final token = await _storage.read(key: _lastTokenKey);
    if (token == null || token.trim().isEmpty) return null;

    final atRaw = await _storage.read(key: _lastTokenAtKey);
    final at = atRaw == null ? null : DateTime.tryParse(atRaw);

    final userId = await _storage.read(key: _lastTokenUserIdKey);
    return (token: token, at: at, userId: (userId ?? '').trim().isEmpty ? null : userId);
  }

  Future<void> clearLastRegisteredToken() async {
    await _storage.delete(key: _lastTokenKey);
    await _storage.delete(key: _lastTokenAtKey);
    await _storage.delete(key: _lastTokenUserIdKey);
  }

  Future<void> savePendingRoute(String route) async {
    final normalized = route.trim();
    if (normalized.isEmpty) return;
    await _storage.write(key: _pendingRouteKey, value: jsonEncode({'route': normalized}));
  }

  Future<String?> readPendingRoute() async {
    final raw = await _storage.read(key: _pendingRouteKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['route'] is String) {
        final route = (decoded['route'] as String).trim();
        return route.isEmpty ? null : route;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingRoute() async {
    await _storage.delete(key: _pendingRouteKey);
  }
}

