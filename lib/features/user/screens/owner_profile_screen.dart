import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:go_router/go_router.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(userProfileProvider);
    final profileImageUrl = state.userProfile?.profileImageUrl ?? "";

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: Icon(
      //       Icons.arrow_back_ios_new_rounded,
      //       size: 20,
      //       color: theme.colorScheme.onPrimary,
      //     ),
      //     onPressed: () => context.pop(),
      //   ),
      // ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 24),
            color: AppColors.teal700,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.surface,
                  child: ClipOval(
                    child: Image.network(
                      profileImageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                DisplayName(),

                const SizedBox(height: 4),
                // Registration Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "Verified Owner",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

                _buildMenuTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: "Registration Status",
                  subtitle: "Fully Verified (Expires 2025)",
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoutes.ownerRegistration);
                  },
                ),

                const SizedBox(height: 12),

                _buildMenuTile(
                  icon: Icons.settings_outlined,
                  title: "App Settings",
                  subtitle: "Notifications, Privacy, Theme",
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoutes.ownerSettings);
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuTile(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  subtitle: "FAQs, Contact Support",
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(AppRoutes.helpSupport);
                  },
                ),

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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return BaseTile(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Icon(icon, color: Colors.blue.shade700),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: trailing,
            onTap: null,
          ),
        ),
      ),
    );
  }
}
