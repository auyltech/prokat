import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/core/widgets/profile_accent_cta.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BecomeOwnerCTA extends ConsumerStatefulWidget {
  const BecomeOwnerCTA({super.key});

  @override
  ConsumerState<BecomeOwnerCTA> createState() => _BecomeOwnerCTAState();
}

class _BecomeOwnerCTAState extends ConsumerState<BecomeOwnerCTA> {
  bool _isRefreshing = false;

  bool _hasOwnerRole() {
    if (ref.read(authProvider).isOwner) return true;
    final role = ref
        .read(clientProfileProvider)
        .userProfile
        ?.role
        ?.toLowerCase();
    return role == 'owner' || role == 'admin';
  }

  Future<void> _refreshApplicationState() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      // Refresh the application first: GET /owner/become-owner repairs
      // APPROVED+CLIENT drift before we mint a session from User.role.
      await ref.read(ownerRegistrationRequestProvider.notifier).refresh();
      if (!mounted) return;
      final request = ref.read(ownerRegistrationRequestProvider).valueOrNull;
      final awaitingModeration = request != null && !request.isApproved;
      // Do not mint an OWNER session while the application is still CREATED.
      if (!awaitingModeration && !ref.read(authProvider).isOwner) {
        await ref.read(authProvider.notifier).refreshSession();
        if (!mounted) return;
      }
      await ref.read(clientProfileProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _enterOwnerMode() async {
    await _refreshApplicationState();
    if (!mounted) return;
    if (ref.read(authProvider).session == null) return;
    final request = ref.read(ownerRegistrationRequestProvider).valueOrNull;
    if (request != null && !request.isApproved) return;
    if (!_hasOwnerRole()) {
      AppToast.show(
        message: AppLocalizations.of(context)!.somethingWentWrongTryAgain,
        type: AppToastType.error,
      );
      return;
    }
    await ref.read(appStartupProvider.notifier).setOwnerMode();
    if (mounted) context.go(AppRoutes.ownerProfile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final registrationRequest = ref
        .watch(ownerRegistrationRequestProvider)
        .valueOrNull;

    final isOwnerJwt = ref.watch(authProvider).isOwner;
    final profileRole = ref
        .watch(clientProfileProvider)
        .userProfile
        ?.role
        ?.toLowerCase();
    final isOwnerRole =
        isOwnerJwt || profileRole == 'owner' || profileRole == 'admin';

    // CREATED/REJECTED wins over User.role=OWNER (local auto-promote setting).
    if (registrationRequest != null) {
      switch (registrationRequest.parsedStatus) {
        case BecomeOwnerRequestStatus.pending:
        case BecomeOwnerRequestStatus.rejected:
          final status = registrationRequest.parsedStatus;
          final config = _getStatusConfig(status, l10n, theme.brightness);
          return ProfileAccentCta(
            leading: Icon(
              config.icon,
              color: config.color,
              size: ProfileAccentCta.iconSize,
            ),
            title: config.label,
            subtitle: _subtitleForRequest(registrationRequest, l10n),
            backgroundColor: config.bg,
            contentColor: config.color,
            trailingIcon: config.trailing,
            isLoading: _isRefreshing,
            onTap: () => _onRequestTap(status),
          );
        case BecomeOwnerRequestStatus.approved:
          break;
      }
    }

    if (isOwnerRole || registrationRequest?.isApproved == true) {
      return ProfileAccentCta(
        leading: ProfileAccentCta.truck(),
        title: l10n.ownerDashboard,
        subtitle: l10n.ownerDashboardSubtitle,
        isLoading: _isRefreshing,
        onTap: _enterOwnerMode,
      );
    }

    return ProfileAccentCta(
      leading: ProfileAccentCta.truckPlus(),
      title: l10n.becomeOwner,
      subtitle: l10n.becomeOwnerSubtitle,
      onTap: () => context.push(AppRoutes.becomeOwner),
    );
  }

  String _subtitleForRequest(
    RegistrationRequestModel request,
    AppLocalizations l10n,
  ) {
    if (request.isRejected) {
      return l10n.statusRejectedSubtitle;
    }

    return l10n.ownerApplicationPendingHint;
  }

  Future<void> _onRequestTap(BecomeOwnerRequestStatus status) async {
    switch (status) {
      case BecomeOwnerRequestStatus.pending:
        await _refreshApplicationState();
        return;
      case BecomeOwnerRequestStatus.rejected:
        if (mounted) unawaited(context.push(AppRoutes.becomeOwner));
        return;
      case BecomeOwnerRequestStatus.approved:
        await _enterOwnerMode();
    }
  }

  _StatusConfig _getStatusConfig(
    BecomeOwnerRequestStatus status,
    AppLocalizations l10n,
    Brightness brightness,
  ) {
    switch (status) {
      case BecomeOwnerRequestStatus.approved:
        return _StatusConfig(
          bg: AppTheme.successBg(brightness),
          color: AppTheme.successFg(brightness),
          icon: LucideIcons.check,
          trailing: LucideIcons.chevronRight,
          label: l10n.requestAccepted,
        );
      case BecomeOwnerRequestStatus.rejected:
        return _StatusConfig(
          bg: AppTheme.dangerBg(brightness),
          color: AppTheme.dangerFg(brightness),
          icon: LucideIcons.circleAlert,
          trailing: LucideIcons.chevronRight,
          label: l10n.requestRejected,
        );
      case BecomeOwnerRequestStatus.pending:
        return _StatusConfig(
          bg: AppTheme.warningBg(brightness),
          color: AppTheme.warningFg(brightness),
          icon: LucideIcons.clock,
          trailing: LucideIcons.refreshCw,
          label: l10n.ownerApplicationPending,
        );
    }
  }
}

class _StatusConfig {
  final Color bg;
  final Color color;
  final IconData icon;
  final IconData trailing;
  final String label;
  _StatusConfig({
    required this.bg,
    required this.color,
    required this.icon,
    required this.trailing,
    required this.label,
  });
}
