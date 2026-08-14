import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/constants/otp_cooldown.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import 'auth_api_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthApiService api;
  final AuthSecureStorage storage;

  AuthNotifier(this.ref, this.api, this.storage) : super(const AuthState());

  Future<void> clearLocalSession() async {
    await storage.clearSession();
    state = const AuthState();
  }

  /// Restore token from secure storage
  Future<AuthSession?> restoreSession() async {
    final session = await storage.readSession();

    if (session != null &&
        (session.sessionToken != null &&
            session.sessionToken?.isNotEmpty == true)) {
      state = state.copyWith(session: session);

      return session;
    }

    state = state.copyWith(session: null);
    return null;
  }

  Future<bool> restoreOtpSession() async {
    final data = await storage.readOtpSession();
    final cooldown = await storage.readOtpCooldown();
    final now = DateTime.now();
    final activeCooldown = cooldown != null && cooldown.retryAt.isAfter(now)
        ? OtpCooldownData(
            phone: cooldown.phone,
            retryAt: _capRetryAt(cooldown.retryAt, now: now),
          )
        : null;

    if (activeCooldown != null && activeCooldown.retryAt != cooldown!.retryAt) {
      await storage.saveOtpCooldown(
        activeCooldown.phone,
        activeCooldown.retryAt,
      );
    }

    if (cooldown != null && activeCooldown == null) {
      await storage.clearOtpCooldown();
    }

    if (data == null) {
      if (activeCooldown != null) {
        state = state.copyWith(
          otpCooldownPhone: activeCooldown.phone,
          otpRetryAt: activeCooldown.retryAt,
        );
      }
      return false;
    }

    final isExpired =
        now.difference(data.requestedAt) > const Duration(minutes: 5);

    if (isExpired) {
      await storage.clearOtpSession();
      if (activeCooldown != null) {
        state = state.copyWith(
          otpCooldownPhone: activeCooldown.phone,
          otpRetryAt: activeCooldown.retryAt,
        );
      }
      return false;
    }

    final storedRetryAt = activeCooldown?.phone == data.phone
        ? activeCooldown?.retryAt
        : data.retryAt;
    final retryAt = storedRetryAt == null
        ? null
        : _capRetryAt(storedRetryAt, now: now);
    state = state.copyWith(
      otpPhone: data.phone,
      otpRequestedAt: data.requestedAt,
      otpCooldownPhone: data.phone,
      otpRetryAt: retryAt,
    );

    return true;
  }

  Future<void> clearOtpSession() async {
    await storage.clearOtpSession();
    await storage.clearOtpCooldown();

    state = state.copyWith(
      otpPhone: null,
      otpRequestedAt: null,
      clearOtp: true,
    );
  }

  Future<bool> refreshSession() async {
    final session = state.session;

    if (session == null) return false;

    try {
      final result = await api.refreshSession();

      if ((result.success) && (result.data != null)) {
        state = state.copyWith(session: result.data);
        await storage.saveSession(result.data as AuthSession);
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// REQUEST OTP
  Future<bool> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);

    try {
      final result = await api.requestOtp(phone);

      if (result.success) {
        final now = DateTime.now();
        final retryAt = _capRetryAt(
          result.retryAt ?? _fallbackRetryAt(now: now),
          now: now,
        );

        // SAVE TO STORAGE
        await storage.saveOtpSession(phone, now, retryAt: retryAt);
        await storage.saveOtpCooldown(phone, retryAt);

        state = state.copyWith(
          isLoading: false,
          otpPhone: phone,
          otpRequestedAt: now,
          otpCooldownPhone: phone,
          otpRetryAt: retryAt,
          error: null,
          errorCode: null,
        );
        return true;
      }

      final isRateLimited =
          result.statusCode == 429 || result.errorCode == 'RATE_LIMITED';
      final shouldStartCooldown = result.retryAt != null || isRateLimited;

      if (shouldStartCooldown) {
        final now = DateTime.now();
        final retryAt = _capRetryAt(
          result.retryAt ?? _fallbackRetryAt(now: now),
          now: now,
        );
        await storage.saveOtpCooldown(phone, retryAt);

        state = state.copyWith(
          isLoading: false,
          otpCooldownPhone: phone,
          otpRetryAt: retryAt,
          error: result.message,
          errorCode:
              result.errorCode ?? (isRateLimited ? 'RATE_LIMITED' : null),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
          errorCode: result.errorCode,
        );
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Failed to request OTP",
        errorCode: null,
      );

      return false;
    }
  }

  DateTime _fallbackRetryAt({DateTime? now}) {
    return (now ?? DateTime.now()).add(otpCooldownDuration);
  }

  DateTime _capRetryAt(DateTime retryAt, {required DateTime now}) {
    final maximumRetryAt = now.add(otpCooldownDuration);
    return retryAt.isAfter(maximumRetryAt) ? maximumRetryAt : retryAt;
  }

  /// VERIFY OTP
  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);

    try {
      final result = await api.verifyOtp(phone, otp);

      if (result.success && result.data != null) {
        await storage.saveSession(result.data!);

        await storage.clearOtpSession();
        await storage.clearOtpCooldown();

        state = state.copyWith(
          session: result.data,
          isLoading: false,
          error: result.success ? null : result.message,
          errorCode: null,
          clearOtp: true,
        );

        // Keep the login route mounted while the authenticated profile is
        // resolved. A full startup reload would route through /launch and
        // make a successful sign-in look like an application restart.
        ref.read(appStartupProvider.notifier).reloadAfterAuthChanged();

        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: result.success ? null : result.message,
        errorCode: result.errorCode,
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification failed',
        errorCode: null,
      );

      return false;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true);

      await api.logout();
      await clearLocalSession();

      state = const AuthState();
    } catch (e) {
      await clearLocalSession();
      state = const AuthState();
    }
  }
}
