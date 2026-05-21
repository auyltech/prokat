import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/widgets/owner_dashboard_header.dart';
import 'package:prokat/features/user/widgets/rent_an_equipment_tile.dart';
import 'package:prokat/features/user/widgets/user_profile_tile.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
                    "Account",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                UserProfileTile(
                  icon: Icons.assignment_turned_in_outlined,
                  label: "Registration Status",
                  value: "Fully Verified (Expires 2025)",
                  onTap: () => context.push(AppRoutes.ownerRegistration),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 12),

                UserProfileTile(
                  icon: Icons.settings_outlined,
                  label: "App Settings",
                  value: "Notifications, Privacy, Theme",
                  onTap: () => context.push(AppRoutes.ownerSettings),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 12),

                UserProfileTile(
                  icon: Icons.help_outline,
                  label: "Help & Support",
                  value: "FAQs, Contact Support",
                  onTap: () => context.push(AppRoutes.helpSupport),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
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
