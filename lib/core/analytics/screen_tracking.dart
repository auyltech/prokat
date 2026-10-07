import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/analytics/analytics_service.dart';
import 'package:prokat/core/router/app_router.dart';
import 'package:prokat/core/router/app_routes.dart';

/// Keys are GoRouter route templates (`fullPath`), never concrete locations.
const Map<String, String> analyticsScreenNames = {
  AppRoutes.main: 'guest_main',
  AppRoutes.searchList: 'client_search',
  AppRoutes.clientProfile: 'client_profile',
  AppRoutes.becomeOwner: 'become_owner',
  AppRoutes.ownerProfile: 'owner_profile',
  AppRoutes.ownerRegistration: 'owner_business_profile',
  AppRoutes.ownerEquipment: 'owner_equipment_list',
  AppRoutes.ownerEquipmentCreate: 'owner_equipment_create',
  AppRoutes.ownerEquipmentId: 'owner_equipment_detail',
};

String? analyticsScreenNameFor(String? fullPath) =>
    fullPath == null ? null : analyticsScreenNames[fullPath];

class ScreenTracker {
  ScreenTracker(this._analytics);

  final AnalyticsService _analytics;
  String? _last;

  void onRoute(String? fullPath) {
    final name = analyticsScreenNameFor(fullPath);
    if (name == null) {
      _last = null;
      return;
    }
    if (name == _last) return;
    _last = name;
    unawaited(_analytics.logScreenView(name));
  }
}

final screenTrackingBootstrapProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);
  final tracker = ScreenTracker(ref.read(analyticsServiceProvider));
  // An unmatched location (GoRouter error page) has no matches, and
  // `router.state` throws on an empty match list.
  void listener() => tracker.onRoute(
    router.routerDelegate.currentConfiguration.isEmpty
        ? null
        : router.state.fullPath,
  );
  router.routerDelegate.addListener(listener);
  ref.onDispose(() => router.routerDelegate.removeListener(listener));
});
