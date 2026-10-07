import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory only: a process kill before the identity listener runs drops it.
class PendingSignUpValue {
  const PendingSignUpValue({required this.userId, this.shareId});

  final String userId;
  final String? shareId;
}

class PendingSignUp {
  PendingSignUpValue? _value;

  void markPending(String userId, {String? shareId}) {
    _value = PendingSignUpValue(userId: userId, shareId: shareId);
  }

  PendingSignUpValue? consume(String userId) {
    final value = _value;
    if (value == null || value.userId != userId) return null;
    _value = null;
    return value;
  }
}

final pendingSignUpProvider = Provider<PendingSignUp>((ref) => PendingSignUp());
