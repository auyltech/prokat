import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/theme/app_theme.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
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
      AppSnackBar.show(
        message: AppLocalizations.of(context)!.somethingWentWrongTryAgain,
        isError: true,
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
          return _buildModernCTA(
            context,
            icon: config.icon,
            title: config.label,
            subtitle: _subtitleForRequest(registrationRequest, l10n),
            bgColor: config.bg,
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
      return _buildModernCTA(
        context,
        icon: Icons.dashboard_customize_outlined,
        title: l10n.ownerDashboard,
        subtitle: l10n.ownerDashboardSubtitle,
        bgColor: AppTheme.accent,
        contentColor: AppTheme.white,
        isLoading: _isRefreshing,
        onTap: _enterOwnerMode,
      );
    }

    final brightness = theme.brightness;
    return _buildModernCTA(
      context,
      icon: Icons.add_business_outlined,
      title: l10n.becomeOwner,
      subtitle: l10n.becomeOwnerSubtitle,
      bgColor: AppTheme.brandTintBg(brightness),
      contentColor: AppTheme.brandTintFg(brightness),
      onTap: () => context.push(AppRoutes.becomeOwner),
    );
  }

  String _subtitleForRequest(
    RegistrationRequestModel request,
    AppLocalizations l10n,
  ) {
    if (request.isRejected) {
      final comment = (request.adminComment ?? '').trim();
      if (comment.isNotEmpty) return comment;
      return l10n.statusRejectedSubtitle;
    }

    return '${l10n.submittedOn} ${formatDate(date: request.createdAt)}';
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

  Widget _buildModernCTA(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color contentColor,
    IconData trailingIcon = Icons.chevron_right,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    final mutedColor = contentColor.withValues(alpha: 0.8);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          children: [
            Icon(icon, color: contentColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: contentColor),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: contentColor,
                ),
              )
            else
              Icon(trailingIcon, color: mutedColor),
          ],
        ),
      ),
    );
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
          icon: Icons.check,
          trailing: Icons.chevron_right,
          label: l10n.requestAccepted,
        );
      case BecomeOwnerRequestStatus.rejected:
        return _StatusConfig(
          bg: AppTheme.dangerBg(brightness),
          color: AppTheme.dangerFg(brightness),
          icon: Icons.error,
          trailing: Icons.chevron_right,
          label: l10n.requestRejected,
        );
      case BecomeOwnerRequestStatus.pending:
        return _StatusConfig(
          bg: AppTheme.warningBg(brightness),
          color: AppTheme.warningFg(brightness),
          icon: Icons.history_toggle_off_rounded,
          trailing: Icons.refresh,
          label: l10n.requestPending,
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
