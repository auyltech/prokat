import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/widgets/owner_dashboard_header.dart';
import 'package:prokat/features/user/widgets/rent_an_equipment_tile.dart';
import 'package:prokat/features/user/widgets/user_profile_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          OwnerDashboardHeader(),

          const SizedBox(height: 24),

          UserProfileTile(
            icon: Icons.assignment_turned_in_outlined,
            label: l10n.registrationStatus,
            value: "Fully Verified (Expires 2025)",
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(AppRoutes.ownerRegistration);
            },
          ),

          const SizedBox(height: 12),

          UserProfileTile(
            icon: Icons.settings_outlined,
            label: l10n.appSettings,
            value: l10n.appSettingsSubtitle,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(AppRoutes.ownerSettings);
            },
          ),

          const SizedBox(height: 12),

          UserProfileTile(
            icon: Icons.help_outline,
            label: l10n.helpSupportTitle,
            value: l10n.helpFaqsSubtitle,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(AppRoutes.helpSupport);
            },
          ),

          const SizedBox(height: 12),

          const Divider(),

          const SizedBox(height: 12),

          RentAnEquipmentTile(),

          const SizedBox(height: 12),

          const Divider(),

          const SizedBox(height: 12),
          LogoutButton(),
        ],
      ),
    );
  }
}
