import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class BecomeOwnerCTA extends ConsumerStatefulWidget {
  const BecomeOwnerCTA({super.key});

  @override
  ConsumerState<BecomeOwnerCTA> createState() => _BecomeOwnerCTAState();
}

class _BecomeOwnerCTAState extends ConsumerState<BecomeOwnerCTA> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final registrationRequestState = ref.watch(ownerRegistrationProvider);
    final registrationRequest = registrationRequestState.registrationRequest;
    final isOwner = ref.watch(userProfileProvider).userProfile?.role == 'OWNER';

    // 1. Owner State
    if (isOwner) {
      return _buildModernCTA(
        context,
        icon: Icons.dashboard_customize_outlined,
        title: l10n.ownerDashboard,
        subtitle: l10n.ownerDashboardSubtitle,
        bgColor: theme.colorScheme.primary,
        contentColor: theme.colorScheme.onPrimary,
        onTap: () async {
          await ref.read(appStartupProvider.notifier).setOwnerMode();
          if (context.mounted) context.go(AppRoutes.ownerProfile);
        },
      );
    }

    // 2. Request Pending/Rejected State
    if (registrationRequest != null) {
      final status = registrationRequest.status?.toUpperCase() ?? 'PENDING';
      final config = _getStatusConfig(status, theme);

      return _buildModernCTA(
        context,
        icon: config.icon,
        title: '${l10n.requestStatus}: ${status.toLowerCase()}',
        subtitle:
            '${l10n.submittedOn} ${formatDate(date: registrationRequest.createdAt)}',
        bgColor: config.bg,
        contentColor: config.text,
        onTap: () => context.push(AppRoutes.becomeOwner),
      );
    }

    // 3. Default "Become an Owner"
    return _buildModernCTA(
      context,
      icon: Icons.add_business_outlined,
      title: l10n.becomeOwner,
      subtitle: l10n.becomeOwnerSubtitle,
      bgColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      contentColor: theme.colorScheme.onSurface,
      onTap: () => context.push(AppRoutes.becomeOwner),
    );
  }

  Widget _buildModernCTA(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color contentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: contentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: contentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: contentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: contentColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: contentColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  _StatusTheme _getStatusConfig(String status, ThemeData theme) {
    switch (status) {
      case 'APPROVED':
        return _StatusTheme(
          bg: const Color(0xFFE8F5E9),
          text: const Color(0xFF2E7D32),
          icon: Icons.check_circle_outline,
        );
      case 'REJECTED':
        return _StatusTheme(
          bg: const Color(0xFFFFEBEE),
          text: const Color(0xFFC62828),
          icon: Icons.error_outline,
        );
      default: // PENDING
        return _StatusTheme(
          bg: const Color(0xFFFFF3E0),
          text: const Color(0xFFE65100),
          icon: Icons.history_toggle_off_rounded,
        );
    }
  }
}

class _StatusTheme {
  final Color bg;
  final Color text;
  final IconData icon;
  _StatusTheme({required this.bg, required this.text, required this.icon});
}
