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
    final state = ref.watch(userProfileProvider);
    final profileImageUrl = state.userProfile?.profileImageUrl ?? "";

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          OwnerDashboardHeader(),

          // 2. Body Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.fullyVerified,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                UserProfileTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: l10n.registrationStatus,
                  subtitle: "Fully Verified (Expires 2025)",
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoutes.ownerRegistration);
                  },
                ),

                const SizedBox(height: 12),

                UserProfileTile(
                  icon: Icons.settings_outlined,
                  title: l10n.appSettings,
                  subtitle: l10n.appSettingsSubtitle,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoutes.ownerSettings);
                  },
                ),

                const SizedBox(height: 12),

                UserProfileTile(
                  icon: Icons.help_outline,
                  title: l10n.helpSupportTitle,
                  subtitle: l10n.helpFaqsSubtitle,
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
          ),
        ],
      ),
    );
  }
}
