import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

enum AppStartupRouteState { loading, guest, otp, client, owner, error }

enum AppStartupStep {
  loadSavedMode,
  restoreSession,
  restoreOtpSession,
  refreshSession,
  fetchProfileMinimal,
  decideRoute,
  done,
}

class AppStartupStatus {
  final AppStartupRouteState routeState;
  final AppStartupStep step;
  final double progress; // 0..1
  final String stepLabel;
  final Map<AppStartupStep, int> timingsMs;
  final String? errorMessage;

  const AppStartupStatus({
    required this.routeState,
    required this.step,
    required this.progress,
    required this.stepLabel,
    this.timingsMs = const {},
    this.errorMessage,
  });

  const AppStartupStatus.loading()
    : routeState = AppStartupRouteState.loading,
      step = AppStartupStep.loadSavedMode,
      progress = 0,
      stepLabel = 'Starting…',
      timingsMs = const {},
      errorMessage = null;

  AppStartupStatus copyWith({
    AppStartupRouteState? routeState,
    AppStartupStep? step,
    double? progress,
    String? stepLabel,
    Map<AppStartupStep, int>? timingsMs,
    String? errorMessage,
  }) {
    return AppStartupStatus(
      routeState: routeState ?? this.routeState,
      step: step ?? this.step,
      progress: progress ?? this.progress,
      stepLabel: stepLabel ?? this.stepLabel,
      timingsMs: timingsMs ?? this.timingsMs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final appStartupProvider =
    StateNotifierProvider<AppStartupController, AppStartupStatus>((ref) {
      return AppStartupController(ref, AppModeStorage());
    });

class AppStartupController extends StateNotifier<AppStartupStatus> {
  final Ref ref;
  final AppModeStorage modeStorage;
  AppMode _currentMode = AppMode.clientMode;
  bool _isInitializing = false;

  AppStartupController(this.ref, this.modeStorage)
    : super(const AppStartupStatus.loading()) {
    Future.microtask(() async {
      // Startup init is triggered from MyApp (lib/app.dart). Keep constructor
      // side effects minimal to avoid duplicate init calls / flicker.
    });
  }

  AppMode get currentMode => _currentMode;
  bool get isClientMode => _currentMode == AppMode.clientMode;
  bool get isOwnerMode => _currentMode == AppMode.ownerMode;

  Future<void> reloadApp() async {
    await init();
  }

  Future<AppMode> loadSavedMode() async {
    final savedMode = await modeStorage.readMode();
    _currentMode = savedMode ?? AppMode.clientMode;
    return _currentMode;
  }

  Future<void> setClientMode() async {
    await _setMode(AppMode.clientMode);
  }

  Future<void> setOwnerMode() async {
    await _setMode(AppMode.ownerMode);
  }

  Future<void> _setMode(AppMode mode) async {
    _currentMode = mode;
    await modeStorage.saveMode(mode);

    if (ref.read(authProvider).session == null) return;

    final profile = ref.read(userProfileProvider).userProfile;
    if (profile == null) {
      await init();
      return;
    }

    state = _statusForStep(
      AppStartupStep.done,
      routeState: _decideRouteFromRole(profile.role),
    );
  }

  AppStartupRouteState _decideRouteFromRole(String? role) {
    final normalized = role?.toLowerCase();
    final isOwnerRole = normalized == 'owner' || normalized == 'admin';

    if (!isOwnerRole) {
      _currentMode = AppMode.clientMode;
      // Persisted mode does not affect routing, but keep it consistent.
      modeStorage.saveMode(_currentMode);
      return AppStartupRouteState.client;
    }

    return isOwnerMode
        ? AppStartupRouteState.owner
        : AppStartupRouteState.client;
  }

  AppStartupStatus _statusForStep(
    AppStartupStep step, {
    AppStartupRouteState? routeState,
    Map<AppStartupStep, int>? timingsMs,
    String? errorMessage,
  }) {
    const steps = AppStartupStep.values;
    final index = steps.indexOf(step).clamp(0, steps.length - 1);
    final progress = steps.length <= 1
        ? 0.0
        : (index / (steps.length - 1)).clamp(0.0, 1.0);

    final label = switch (step) {
      AppStartupStep.loadSavedMode => 'Loading app mode…',
      AppStartupStep.restoreSession => 'Restoring session…',
      AppStartupStep.restoreOtpSession => 'Restoring OTP session…',
      AppStartupStep.refreshSession => 'Refreshing session…',
      AppStartupStep.fetchProfileMinimal => 'Loading profile…',
      AppStartupStep.decideRoute => 'Finalizing…',
      AppStartupStep.done => 'Done',
    };

    return state.copyWith(
      routeState: routeState ?? state.routeState,
      step: step,
      progress: progress,
      stepLabel: label,
      timingsMs: timingsMs ?? state.timingsMs,
      errorMessage: errorMessage,
    );
  }

  Future<void> init() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      state = _statusForStep(
        AppStartupStep.loadSavedMode,
        routeState: AppStartupRouteState.loading,
      );

      final timings = <AppStartupStep, int>{};

      Future<T> measure<T>(AppStartupStep step, Future<T> Function() fn) async {
        final start = DateTime.now();
        final result = await fn();
        if (!kReleaseMode) {
          timings[step] = DateTime.now().difference(start).inMilliseconds;
          state = state.copyWith(timingsMs: Map.unmodifiable(timings));
        }
        return result;
      }

      await measure(AppStartupStep.loadSavedMode, loadSavedMode);

      final auth = ref.read(authProvider.notifier);

      state = _statusForStep(AppStartupStep.restoreSession);
      final session = await measure(
        AppStartupStep.restoreSession,
        auth.restoreSession,
      );

      if (session == null) {
        state = _statusForStep(AppStartupStep.restoreOtpSession);
        final otpSession = await measure(
          AppStartupStep.restoreOtpSession,
          auth.restoreOtpSession,
        );

        state = _statusForStep(
          AppStartupStep.done,
          routeState: otpSession == true
              ? AppStartupRouteState.otp
              : AppStartupRouteState.guest,
        );

        return;
      }

      state = _statusForStep(AppStartupStep.refreshSession);
      final isValid = await measure(
        AppStartupStep.refreshSession,
        auth.refreshSession,
      );

      if (!isValid) {
        state = _statusForStep(
          AppStartupStep.done,
          routeState: AppStartupRouteState.guest,
        );
        return;
      }

      state = _statusForStep(AppStartupStep.fetchProfileMinimal);
      await measure(
        AppStartupStep.fetchProfileMinimal,
        () => ref.read(userProfileProvider.notifier).getUserProfile(),
      );

      final profile = ref.read(userProfileProvider).userProfile;
      if (profile == null) {
        state = _statusForStep(
          AppStartupStep.done,
          routeState: AppStartupRouteState.guest,
        );
        return;
      }

      state = _statusForStep(AppStartupStep.decideRoute);
      final route = _decideRouteFromRole(profile.role);
      state = _statusForStep(AppStartupStep.done, routeState: route);
    } catch (e) {
      state = _statusForStep(
        AppStartupStep.done,
        routeState: AppStartupRouteState.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isInitializing = false;
    }
  }
}
