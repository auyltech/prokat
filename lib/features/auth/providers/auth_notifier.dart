import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/models/auth_session.dart';
import 'package:prokat/features/auth/providers/auth_secure_storage.dart';
import '../models/auth_credentials.dart';
import 'auth_api_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthApiService api;
  final AuthSecureStorage storage;

  AuthNotifier(this.ref, this.api, this.storage) : super(const AuthState()) {
    // restore session in app startup provider: below can cause flickers/async side effect
    // restoreSession();
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

    return null;
  }

  Future<bool> restoreOtpSession() async {
    final data = await storage.readOtpSession();

    if (data == null) return false;

    final isExpired =
        DateTime.now().difference(data.requestedAt) >
        const Duration(minutes: 5);

    if (isExpired) {
      await storage.clearOtpSession();
      return false;
    }

    state = state.copyWith(
      otpPhone: data.phone,
      otpRequestedAt: data.requestedAt,
    );

    return true;
  }

  Future<void> clearOtpSession() async {
    await storage.clearOtpSession();

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
      final refreshed = await api.refreshSession();

      if (refreshed == null) {
        await logout();
        return false;
      }

      state = state.copyWith(session: refreshed);
      await storage.saveSession(refreshed);

      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  /// LOGIN WITH USERNAME/PASSWORD
  Future<bool> loginCredentials(LoginCredentials credentials) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await api.loginWithCredentials(credentials);

      if (result.success && result.data != null) {
        await storage.saveSession(result.data as AuthSession);

        await ref.read(appStartupProvider.notifier).reloadApp();

        state = state.copyWith(session: result.data, isLoading: false);

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.error);

        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// REGISTER USER WITH NAME, USERNAME PASSWORD
  Future<bool> registerCredentials(RegisterCredentials credentials) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await api.registerCredentials(credentials);

      if (result.success && result.data != null) {
        await storage.saveSession(result.data as AuthSession);

        await ref.read(appStartupProvider.notifier).reloadApp();

        state = state.copyWith(session: result.data, isLoading: false);

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.error);

        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Registration failed');

      return false;
    }
  }

  /// REQUEST OTP
  Future<bool> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await api.requestOtp(phone);

      if (success) {
        final now = DateTime.now();

        // SAVE TO STORAGE
        await storage.saveOtpSession(phone, now);

        state = state.copyWith(
          isLoading: false,
          otpPhone: phone,
          otpRequestedAt: now,
        );
      }

      state = state.copyWith(isLoading: false);

      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Failed to request OTP");
      return false;
    }
  }

  /// VERIFY OTP
  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await api.verifyOtp(phone, otp);

      if (result.data != null) {
        await storage.saveSession(result.data as AuthSession);

        await storage.clearOtpSession();

        state = state.copyWith(session: result.data, isLoading: false);

        await ref.read(appStartupProvider.notifier).reloadApp();

        return true;
      }

      state = state.copyWith(isLoading: false);

      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed');

      return false;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true);

      await api.logout();

      await storage.clearSession();

      state = const AuthState();
    } catch (e) {
      await storage.clearSession();
      state = const AuthState();
    }
  }
}
