import 'dart:async';

import 'package:prokat/core/updates/emergency_update_config.dart';

class FakeEmergencyConfigClient implements EmergencyConfigClient {
  final values = <String, String>{};
  final pending = <String, String>{};
  final events = StreamController<Set<String>>.broadcast();
  final keysRead = <String>[];
  bool failFetch = false;
  bool failPrepare = false;
  bool failActivate = false;
  bool failRead = false;
  Future<bool>? fetchReply;
  int fetchCalls = 0;
  int prepareCalls = 0;
  int activationCalls = 0;

  @override
  String getString(String key) {
    keysRead.add(key);
    if (failRead) throw StateError('cache unavailable');
    return values[key] ?? '';
  }

  @override
  Future<void> prepare() async {
    prepareCalls++;
    if (failPrepare) throw StateError('initialization unavailable');
  }

  @override
  Future<bool> fetchAndActivate() async {
    fetchCalls++;
    if (failFetch) throw StateError('offline');
    if (fetchReply != null) return fetchReply!;
    values.addAll(pending);
    return true;
  }

  @override
  Future<bool> activate() async {
    activationCalls++;
    if (failActivate) throw StateError('activation unavailable');
    values.addAll(pending);
    return true;
  }

  @override
  Stream<Set<String>> get updates => events.stream;
}
