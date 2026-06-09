import 'package:prokat/features/auth/models/auth_session.dart';

class AuthState {
  final AuthSession? session;

  final bool isLoading;
  final String? error;
  final String? success;

  final String? otpPhone;
  final DateTime? otpRequestedAt;

  bool get isOtpActive =>
      otpPhone != null &&
      otpRequestedAt != null &&
      DateTime.now().difference(otpRequestedAt!) < const Duration(minutes: 5);

  const AuthState({
    this.session,
    this.isLoading = false,
    this.error,
    this.success,
    this.otpPhone,
    this.otpRequestedAt,
  });

  bool get isAuthenticated => session != null;
  bool get isOwner => session?.user?.role == "OWNER";

  AuthState copyWith({
    AuthSession? session,
    bool? isLoading,
    String? error,
    String? otpPhone,
    DateTime? otpRequestedAt,
    bool clearOtp = false,
  }) {
    return AuthState(
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otpPhone: clearOtp ? null : (otpPhone ?? this.otpPhone),
      otpRequestedAt: clearOtp ? null : (otpRequestedAt ?? this.otpRequestedAt),
    );
  }
}
