import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/widgets/logout_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/widgets/rent_an_equipment_tile.dart';
import 'package:prokat/features/user/widgets/user_profile_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final ownerProfileState = ref.watch(ownerRegistrationProvider);

    print(ownerProfileState.ownerProfile?.ratingAverage ?? 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.watch(ownerRegistrationProvider.notifier).getOwnerProfile();
        },
        child: ListView(
          padding: EdgeInsets.all(24),
          children: [
            Row(
              children: [
                // Profile Image
                ProfileImagePicker(
                  onImageSelected: (file) async {
                    if (file != null) {
                      await ref
                          .read(userProfileProvider.notifier)
                          .uploadProfileImage(file);
                    }
                  },
                  initialImageUrl:
                      ownerProfileState.ownerProfile?.profileImageUrl ?? "",
                ),

                const SizedBox(width: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const DisplayName(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (ownerProfileState.ownerProfile?.ratingAverage ?? 0)
                              .toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "- ${ownerProfileState.ownerProfile?.ratingCount ?? 0} ratings",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "- ${ownerProfileState.ownerProfile?.orderCount ?? 0} ${l10n.navOrders}",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

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

            RentAnEquipmentTile(),

            const SizedBox(height: 12),

            const Divider(),

            const SizedBox(height: 12),
            LogoutButton(),
          ],
        ),
      ),
    );
  }
}
