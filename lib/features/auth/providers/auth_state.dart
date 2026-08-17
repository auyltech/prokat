import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/models/user_model.dart';

class AuthState {
  static const _notProvided = Object();

  final AuthSession? session;

  final bool isLoading;
  final String? error;
  final String? errorCode;
  final String? success;

  final String? otpPhone;
  final DateTime? otpRequestedAt;
  final String? otpCooldownPhone;
  final DateTime? otpRetryAt;

  bool get isOtpActive =>
      otpPhone != null &&
      otpRequestedAt != null &&
      DateTime.now().difference(otpRequestedAt!) < const Duration(minutes: 5);

  const AuthState({
    this.session,
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.success,
    this.otpPhone,
    this.otpRequestedAt,
    this.otpCooldownPhone,
    this.otpRetryAt,
  });

  bool get isAuthenticated => session != null;
  bool get isOwner => session?.user?.role == UserRole.owner;

  String? get currentUserId {
    return session?.user?.id;
  }

  AuthState copyWith({
    Object? session = _notProvided,
    bool? isLoading,
    String? error,
    String? errorCode,
    String? otpPhone,
    DateTime? otpRequestedAt,
    String? otpCooldownPhone,
    DateTime? otpRetryAt,
    bool clearOtp = false,
  }) {
    assert(
      identical(session, _notProvided) || session is AuthSession?,
      'session must be an AuthSession or null',
    );

    return AuthState(
      session: identical(session, _notProvided)
          ? this.session
          : session as AuthSession?,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorCode: errorCode,
      otpPhone: clearOtp ? null : (otpPhone ?? this.otpPhone),
      otpRequestedAt: clearOtp ? null : (otpRequestedAt ?? this.otpRequestedAt),
      otpCooldownPhone: clearOtp
          ? null
          : (otpCooldownPhone ?? this.otpCooldownPhone),
      otpRetryAt: clearOtp ? null : (otpRetryAt ?? this.otpRetryAt),
    );
  }
}
