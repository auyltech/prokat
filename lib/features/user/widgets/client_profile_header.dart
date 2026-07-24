import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/features/user/widgets/display_name.dart';

class ClientProfileHeader extends StatelessWidget {
  final UserProfileModel? userProfile;

  const ClientProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      // margin: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF002C63), // Your original primary color
            Color(0xFF004B87), // A lighter blue for the gradient effect
          ],
        ),
        // borderRadius: const BorderRadius.all(Radius.circular(28)),
      ),
      // SafeArea prevents content from clipping into the status bar notch
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfileImagePicker(
              initialImageUrl: userProfile?.profileImageUrl ?? "",
              mode: AppMode.clientMode,
            ),

            SizedBox(height: 12),

            const DisplayName(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.star, size: 20, color: Colors.amber),

                const SizedBox(width: 6),

                Text(
                  (userProfile?.ratingAverage ?? 0).toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  "- ${userProfile?.orderCount ?? 0} orders",
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
