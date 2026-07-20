import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
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

    final registrationRequest = ref
        .watch(ownerRegistrationProvider)
        .registrationRequest;

    final isOwner = ref.watch(authProvider).isOwner;

    // 1. Owner State
    if (isOwner) {
      return _buildModernCTA(
        context,
        icon: Icons.dashboard_customize_outlined,
        title: l10n.ownerDashboard,
        subtitle: l10n.ownerDashboardSubtitle,
        bgColor: theme.colorScheme.primary,
        contentColor: theme.colorScheme.onPrimary,
        isPrimary: true,
        onTap: () async {
          await ref.read(appStartupProvider.notifier).setOwnerMode();
          if (context.mounted) context.go(AppRoutes.ownerProfile);
        },
      );
    }

    // 2. Request Pending/Rejected State
    if (registrationRequest != null) {
      final config = _getStatusConfig(
        registrationRequest.status?.toUpperCase() ?? 'PENDING',
        theme,
      );

      return _buildModernCTA(
        context,
        icon: config.icon,
        title: config.label,
        subtitle:
            '${l10n.submittedOn} ${formatDate(date: registrationRequest.createdAt)}',
        bgColor: config.bg,
        contentColor: config.color,
        onTap: () => context.push(AppRoutes.becomeOwner),
      );
    }

    // 3. Default "Become an Owner"
    return _buildModernCTA(
      context,
      icon: Icons.add_business_outlined,
      title: l10n.becomeOwner,
      subtitle: l10n.becomeOwnerSubtitle,
      bgColor: theme.colorScheme.surfaceBright,
      contentColor: theme.colorScheme.primary,
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
    bool? isPrimary = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      // fontWeight: FontWeight.bold,
                      color: contentColor,
                      // letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPrimary == true
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isPrimary == true
                  ? Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.7)
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status, ThemeData theme) {
    switch (status) {
      case 'APPROVED':
        return _StatusConfig(
          bg: const Color(0xFFE8F5E9),
          color: const Color(0xFF2E7D32),
          icon: Icons.check,
          label: "Request Accepted",
        );
      case 'REJECTED':
        return _StatusConfig(
          bg: const Color(0xFFFFEBEE),
          color: const Color(0xFFC62828),
          icon: Icons.error,
          label: "Request Rejected",
        );
      default: // PENDING
        return _StatusConfig(
          bg: const Color(0xFFFFF3E0),
          color: const Color(0xFFE65100),
          icon: Icons.history_toggle_off_rounded,
          label: "Request Pending",
        );
    }
  }
}

class _StatusConfig {
  final Color bg;
  final Color color;
  final IconData icon;
  final String label;
  _StatusConfig({
    required this.bg,
    required this.color,
    required this.icon,
    required this.label,
  });
}
