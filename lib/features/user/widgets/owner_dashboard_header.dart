import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';

class OwnerDashboardHeader extends ConsumerStatefulWidget {
  const OwnerDashboardHeader({super.key});

  @override
  ConsumerState<OwnerDashboardHeader> createState() =>
      _OwnerDashboardHeaderState();
}

class _OwnerDashboardHeaderState extends ConsumerState<OwnerDashboardHeader> {
  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final profileNotifier = ref.read(userProfileProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);

    final ratingStars = userProfileState.userProfile?.ratingStars ?? 0;

    return Row(
      children: [
        // Profile Image
        ProfileImagePicker(
          onImageSelected: (file) async {
            if (file != null) {
              await profileNotifier.uploadProfileImage(file);
            }
          },
          initialImageUrl: userProfileState.userProfile?.profileImageUrl ?? "",
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
                const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  ratingStars.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  (ratingStars).toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "- 0 ${l10n.navOrders}",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
