import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerProfileHeader extends StatelessWidget {
  final OwnerProfileModel? ownerProfile;
  final List<Color> gradientColors;
  final AppMode avatarMode;
  final bool showRating;
  final Future<void> Function(File)? onAvatarUpload;
  final Future<void> Function()? onAvatarDelete;
  const OwnerProfileHeader({
    super.key,
    required this.ownerProfile,
    this.gradientColors = const [AppColors.teal800, AppColors.teal700],
    this.avatarMode = AppMode.ownerMode,
    this.showRating = true,
    this.onAvatarUpload,
    this.onAvatarDelete,
  });

  String _ownerDisplayName(AppLocalizations l10n) {
    final name = ownerProfile?.firstName?.trim() ?? '';
    return name.isNotEmpty ? name : l10n.hello;
  }

  @override
  Widget build(BuildContext context) {
    if (ownerProfile == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final flow = ProkatFlowScope.maybeOf(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.teal800,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: flow == null
            ? BorderRadius.circular(0)
            : const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      // Keep status bar area tinted correctly
      child: SafeArea(
        top: flow != null,
        bottom: false,
        left: flow != null,
        right: flow != null,
        child: Column(
          mainAxisSize: flow == null ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: flow == null ? 80 : 28),

            // ── Avatar ──
            ProfileImagePicker(
              initialImageUrl: ownerProfile?.profileImageUrl ?? "",
              mode: avatarMode,
              radius: flow == null ? 80 : 56,
              onUpload: onAvatarUpload,
              onDelete: onAvatarDelete,
            ),

            const SizedBox(height: 10),

            // ── Name ──
            Text(
              _ownerDisplayName(l10n),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: flow == null ? 2 : null,
              overflow: flow == null
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
            ),

            // ── Rating ──
            if (showRating)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.star, size: 20, color: Colors.amber),

                  const SizedBox(width: 4),

                  Text(
                    (ownerProfile?.ratingAverage ?? 0) <= 0
                        ? l10n.listingNoReviews
                        : (ownerProfile?.ratingAverage ?? 0).toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                  // TODO(Vadim): Временно скрыто (Разобраться)
                  // const SizedBox(width: 12),
                  //
                  // Text(
                  //   "${ownerProfile?.ratingCount ?? 0} rating${ownerProfile?.ratingCount == 1 ? "" : "s"}",
                  //   style: TextStyle(
                  //     color: Colors.white.withValues(alpha: 0.75),
                  //     fontSize: 14,
                  //   ),
                  // ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
