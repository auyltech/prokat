import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/updates/app_update_policy.dart';
import 'package:prokat/core/utils/logger.dart';

const emergencyVersionDefaults = <String, Object>{
  'min_supported_version_android': '',
  'min_supported_version_ios': '',
};

String? emergencyVersionKey(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android => 'min_supported_version_android',
  TargetPlatform.iOS => 'min_supported_version_ios',
  _ => null,
};

/// Small injectable transport boundary; policy tests never call Firebase.
abstract interface class EmergencyConfigClient {
  String getString(String key);
  Future<void> prepare();
  Future<bool> fetchAndActivate();
  Future<bool> activate();
  Stream<Set<String>> get updates;
}

class FirebaseEmergencyConfigClient implements EmergencyConfigClient {
  FirebaseEmergencyConfigClient(this.config);
  final FirebaseRemoteConfig config;

  @override
  String getString(String key) => config.getString(key);

  @override
  Future<void> prepare() async {
    await config.ensureInitialized();
    await config.setDefaults(emergencyVersionDefaults);
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
  }

  @override
  Future<bool> fetchAndActivate() => config.fetchAndActivate();

  @override
  Future<bool> activate() => config.activate();

  @override
  Stream<Set<String>> get updates =>
      config.onConfigUpdated.map((event) => event.updatedKeys);
}

class EmergencyMinimumController extends StateNotifier<String?> {
  EmergencyMinimumController({
    required this.platform,
    this.client,
    this.timeout = const Duration(seconds: 15),
    bool autoStart = true,
    void Function(Object)? log,
  }) : _log = log ?? Logger.log,
       super(null) {
    _readActivated();
    if (autoStart) unawaited(start());
  }

  final TargetPlatform platform;
  final EmergencyConfigClient? client;
  final Duration timeout;
  final void Function(Object) _log;
  StreamSubscription<Set<String>>? _subscription;
  Future<void>? _starting;
  Future<void> _activation = Future<void>.value();
  bool _disposed = false;

  void _readActivated() {
    final key = emergencyVersionKey(platform);
    if (_disposed || client == null || key == null) return;
    try {
      final raw = client!.getString(key).trim();
      final parsed = parseAppVersion(raw);
      if (raw.isNotEmpty && parsed == null) {
        _log(
          'Invalid Remote Config emergency minimum for $key: "$raw"; ignored.',
        );
      }
      final next = parsed?.toString();
      if (next != state) state = next;
    } catch (error) {
      _log('Emergency minimum cache unavailable: $error');
    }
  }

  /// Called once by the provider after FirebaseBootstrap; never awaited by app
  /// startup. Activated cache is read immediately, before any network request.
  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    final source = client;
    final key = emergencyVersionKey(platform);
    if (source == null || key == null || _disposed) return;
    try {
      await source.prepare().timeout(timeout);
    } catch (error) {
      _log('Emergency Remote Config initialization failed: $error');
    }
    if (_disposed) return;
    _readActivated();
    try {
      _subscription = source.updates.listen(
        (keys) {
          if (!keys.contains(key)) return;
          // Real-time SDK events already fetch; activate serially, never poll.
          _activation = _activation.then((_) async {
            if (_disposed) return;
            try {
              await source.activate().timeout(timeout);
              _readActivated();
            } catch (error) {
              _log('Emergency Remote Config activation failed: $error');
            }
          });
        },
        onError: (Object error) {
          _log('Emergency Remote Config listener failed: $error');
        },
      );
    } catch (error) {
      _log('Emergency Remote Config listener unavailable: $error');
    }
    try {
      await source.fetchAndActivate().timeout(timeout);
      _readActivated();
    } catch (error) {
      // Preserve the last activated value; a failed fetch must not erase it.
      _log('Emergency Remote Config fetch failed; keeping cache: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final emergencyMinimumProvider =
    StateNotifierProvider<EmergencyMinimumController, String?>((ref) {
      EmergencyConfigClient? client;
      if (Env.firebaseServicesEnabled &&
          !Env.isLocal &&
          !kIsWeb &&
          emergencyVersionKey(defaultTargetPlatform) != null &&
          Firebase.apps.isNotEmpty) {
        try {
          client = FirebaseEmergencyConfigClient(FirebaseRemoteConfig.instance);
        } catch (error) {
          Logger.log('Emergency Remote Config unavailable: $error');
        }
      }
      return EmergencyMinimumController(
        platform: defaultTargetPlatform,
        client: client,
      );
    });
