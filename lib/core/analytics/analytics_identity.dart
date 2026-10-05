import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/analytics/analytics_events.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/analytics/pending_sign_up.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';

class AnalyticsIdentity {
  const AnalyticsIdentity({this.userId, this.role});

  final String? userId;
  final String? role;

  @override
  bool operator ==(Object other) =>
      other is AnalyticsIdentity &&
      other.userId == userId &&
      other.role == role;

  @override
  int get hashCode => Object.hash(userId, role);
}

AnalyticsIdentity resolveAnalyticsIdentity({
  String? userId,
  required bool jwtIsOwner,
  String? profileRole,
}) {
  if (userId == null) return const AnalyticsIdentity();

  final normalizedRole = profileRole?.trim().toLowerCase();
  final isOwner =
      jwtIsOwner || normalizedRole == 'owner' || normalizedRole == 'admin';

  return AnalyticsIdentity(
    userId: userId,
    role: isOwner
        ? AnalyticsUserProperties.roleOwner
        : AnalyticsUserProperties.roleClient,
  );
}

final analyticsIdentityProvider = Provider<AnalyticsIdentity>((ref) {
  final auth = ref.watch(
    authProvider.select((s) => (s.currentUserId, s.isOwner)),
  );
  final role = ref.watch(
    clientProfileProvider.select((s) => s.userProfile?.role),
  );
  return resolveAnalyticsIdentity(
    userId: auth.$1,
    jwtIsOwner: auth.$2,
    profileRole: role,
  );
});

final analyticsIdentityBootstrapProvider = Provider<void>((ref) {
  var applying = Future<void>.value();

  ref.listen<AnalyticsIdentity>(analyticsIdentityProvider, (prev, next) {
    if (prev == next) return;
    final analytics = ref.read(analyticsServiceProvider);
    final pendingSignUp = ref.read(pendingSignUpProvider);
    applying = applying.then(
      (_) => _applyIdentity(analytics, pendingSignUp, next),
    );
  }, fireImmediately: true);
});

/// Applications are chained so a later identity never interleaves with an
/// earlier one, and sign_up is only sent after its user's identity is set.
Future<void> _applyIdentity(
  AnalyticsService analytics,
  PendingSignUp pendingSignUp,
  AnalyticsIdentity identity,
) async {
  try {
    await analytics.setIdentity(identity);
    final userId = identity.userId;
    if (userId != null && pendingSignUp.consume(userId)) {
      await analytics.logSignUp();
    }
  } catch (_) {}
}
