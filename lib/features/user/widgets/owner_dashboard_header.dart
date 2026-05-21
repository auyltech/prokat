import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';

class OwnerDashboardHeader extends ConsumerStatefulWidget {
  const OwnerDashboardHeader({super.key});

  @override
  ConsumerState<OwnerDashboardHeader> createState() =>
      _OwnerDashboardHeaderState();
}

class _OwnerDashboardHeaderState extends ConsumerState<OwnerDashboardHeader> {
  String selectedLanguage = 'EN';

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final profileNotifier = ref.read(userProfileProvider.notifier);

    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF006B54), const Color(0xFF008E7D)],
        ),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Profile Image
          ProfileImagePicker(
            onImageSelected: (file) async {
              if (file != null) {
                await profileNotifier.uploadProfileImage(file);
              }
            },
            initialImageUrl:
                userProfileState.userProfile?.profileImageUrl ?? "",
          ),

          const SizedBox(width: 16),

          // Name and Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  userProfileState.userProfile?.displayName ?? 'Hello!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),

                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      (userProfileState.userProfile?.ratingStars ?? 0)
                          .toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${(userProfileState.userProfile?.ratingStars ?? 0).toStringAsFixed(0)} reviews)',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat Button
          IconButton(
            // Adds internal padding between the icon and the button edge
            padding: const EdgeInsets.all(12),
            icon: Icon(
              LucideIcons.messageSquare,
              size: 24,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: () {
              context.push(AppRoutes.ownerChat);
            },
          ),
        ],
      ),
    );
  }
}
