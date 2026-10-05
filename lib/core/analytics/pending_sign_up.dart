import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory only: a process kill before the identity listener runs drops it.
class PendingSignUp {
  String? _userId;

  void markPending(String userId) => _userId = userId;

  bool consume(String userId) {
    if (_userId != userId) return false;
    _userId = null;
    return true;
  }
}

final pendingSignUpProvider = Provider<PendingSignUp>((ref) => PendingSignUp());
