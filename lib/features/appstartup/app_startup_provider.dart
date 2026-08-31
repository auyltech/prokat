import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/socket_provider.dart';
import 'package:prokat/core/providers/unauthorized_signal_provider.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/providers/booking_provider.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/client_history_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_history_bookings_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/notifications/providers/notification_navigation_service_provider.dart';
import 'package:prokat/features/notifications/providers/notification_provider.dart';
import 'package:prokat/features/notifications/providers/push_notification_service_provider.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/client_history_requests_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/features/support/state/support_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';

enum AppStartupRouteState {
  loading,
  guest,
  otp,
  client,
  owner,
  unauthorized,
  error,
}

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
  Future<void>? _signOut;
  Future<void>? _unauthorizedSignOut;

  AppStartupController(this.ref, this.modeStorage)
    : super(const AppStartupStatus.loading()) {
    ref.listen<int>(unauthorizedSignalProvider, (prev, next) {
      if (prev == next) return;
      unawaited(_handleUnauthorized());
    });
  }

  AppMode get currentMode => _currentMode;
  bool get isClientMode => _currentMode == AppMode.clientMode;
  bool get isOwnerMode => _currentMode == AppMode.ownerMode;

  Future<void> reloadApp() async {
    await init();
  }

  Future<void> reloadAfterAuthChanged() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      await loadSavedMode();

      // OTP verification has already persisted and published this session.
      // Do not run the cold-start restore/refresh pipeline a second time.
      if (ref.read(authProvider).session == null) {
        state = _statusForStep(
          AppStartupStep.done,
          routeState: AppStartupRouteState.guest,
        );
        return;
      }

      // Preserve the current OTP/login route while the minimum profile is
      // loaded. The final state change lets GoRouter perform one transition.
      state = _statusForStep(AppStartupStep.fetchProfileMinimal);

      await ref.read(clientProfileProvider.notifier).refresh();

      final profile = ref.read(clientProfileProvider).userProfile;

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
        errorMessage: "Something went wrong!", //e.toString(),
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _handleUnauthorized() {
    // A delayed 401 from an in-flight request after local logout must not
    // start another remote logout or turn the guest route into unauthorized.
    if (ref.read(authProvider).session == null) {
      return Future<void>.value();
    }

    final active = _unauthorizedSignOut;
    if (active != null) return active;

    late final Future<void> tracked;
    tracked = forceSignedOut(unauthorized: true).whenComplete(() {
      if (identical(_unauthorizedSignOut, tracked)) {
        _unauthorizedSignOut = null;
      }
    });
    _unauthorizedSignOut = tracked;
    return tracked;
  }

  Future<void> _clearUserScopedProviders() async {
    // Profile and owner registration
    ref.invalidate(clientProfileProvider);
    ref.invalidate(clientProfileMutationProvider);
    ref.invalidate(ownerProfileProvider);
    ref.invalidate(ownerRegistrationRequestProvider);
    ref.invalidate(ownerRegistrationMutationProvider);

    // User addresses and profile-derived selections
    ref.invalidate(locationProvider);
    ref.invalidate(selectedCategoryProvider);

    // Search state and personalized equipment
    ref.invalidate(searchEquipmentProvider);
    ref.invalidate(clientEquipmentProvider);
    ref.invalidate(ownerEquipmentProvider);
    ref.invalidate(ownerEquipmentDetailsProvider);
    ref.invalidate(equipmentMutationProvider);

    // Map state can retain selected/personalized equipment.
    // ref.invalidate(equipmentMapProvider);
    // ref.invalidate(mapControllerProvider);

    // Favorites
    ref.invalidate(favoritesProvider);

    // Billing
    ref.invalidate(billingProvider);

    // Client bookings
    ref.invalidate(clientActiveBookingsProvider);
    ref.invalidate(clientHistoryBookingsProvider);

    // Owner bookings
    ref.invalidate(ownerActiveBookingsProvider);
    ref.invalidate(ownerHistoryBookingsProvider);

    // Booking details and unfinished booking forms
    ref.invalidate(bookingProvider);
    ref.invalidate(bookingMutationProvider);

    // Client requests
    ref.invalidate(clientActiveRequestsProvider);
    ref.invalidate(clientHistoryRequestsProvider);

    // Owner requests
    ref.invalidate(ownerActiveRequestsProvider);

    // Request drafts and mutations
    ref.invalidate(requestMutationProvider);

    // Offers and negotiations
    ref.invalidate(clientOffersProvider);
    ref.invalidate(ownerOffersProvider);
    ref.invalidate(offerMutationProvider);
    ref.invalidate(priceNegotiationsProvider);
    ref.invalidate(priceNegotiationMutationProvider);

    // Chat lists and all family instances
    ref.invalidate(clientChatsByFilterProvider);
    ref.invalidate(ownerChatsByFilterProvider);
    ref.invalidate(currentChatProvider);
    ref.invalidate(chatMessagesProvider);
    ref.invalidate(chatResolverProvider);

    // Dispose chat socket listeners after chat providers.
    ref.invalidate(chatSocketServiceProvider);

    // Booking-specific review state
    ref.invalidate(reviewByBookingProvider);

    // Optional: clears in-progress support submission state.
    ref.invalidate(supportProvider);

    ref.read(notificationProvider.notifier).clearOnLogout();
    ref.read(appSocketProvider).disconnectSocket();

    await ref.read(notificationLocalStorageProvider).clearPendingRoute();
  }

  Future<void> forceSignedOut({bool unauthorized = false}) {
    final active = _signOut;
    if (active != null) return active;

    late final Future<void> tracked;
    tracked = _forceSignedOut(unauthorized: unauthorized).whenComplete(() {
      if (identical(_signOut, tracked)) {
        _signOut = null;
      }
    });
    _signOut = tracked;
    return tracked;
  }

  Future<void> _forceSignedOut({required bool unauthorized}) async {
    final authNotifier = ref.read(authProvider.notifier);

    try {
      try {
        await ref
            .read(pushNotificationServiceProvider)
            .deactivateCurrentDevice();
      } catch (_) {
        // Push-token cleanup must not prevent logout.
      }

      await authNotifier.logout();
      // TODO: clear Providers (profile, billing, categories, equipment)
    } catch (_) {
      // Ignore errors to ensure we still force reroute.

      // Guarantee that the local session is removed.
      await authNotifier.clearLocalSession();
    }

    state = _statusForStep(
      AppStartupStep.done,
      routeState: unauthorized
          ? AppStartupRouteState.unauthorized
          : AppStartupRouteState.guest,
    );

    await WidgetsBinding.instance.endOfFrame;

    await _clearUserScopedProviders();
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

    final profile = ref.read(clientProfileProvider).userProfile;

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
      unawaited(modeStorage.saveMode(_currentMode));

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
        () => ref.read(clientProfileProvider.notifier).refresh(),
      );

      final profile = ref.read(clientProfileProvider).userProfile;

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
        errorMessage:
            "An unexpected error occurred during application startup. Please try again.",
      );
    } finally {
      _isInitializing = false;
    }
  }
}
