import 'package:flutter/material.dart';
import 'package:prokat/core/constants/app_colors.dart';
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
  const OwnerProfileHeader({
    super.key,
    required this.ownerProfile,
    this.gradientColors = const [AppColors.teal800, AppColors.teal700],
    this.avatarMode = AppMode.ownerMode,
    this.showRating = true,
  });

  String _ownerDisplayName(AppLocalizations l10n) {
    final name = [ownerProfile?.firstName, ownerProfile?.lastName]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .join(' ');
    return name.isNotEmpty ? name : l10n.hello;
  }

  @override
  Widget build(BuildContext context) {
    if (ownerProfile == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
        borderRadius: BorderRadius.circular(0),
      ),
      // Keep status bar area tinted correctly
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),

          // ── Avatar ──
          ProfileImagePicker(
            initialImageUrl: ownerProfile?.profileImageUrl ?? "",
            mode: avatarMode,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // ── Rating ──
          if (showRating)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.star, size: 20, color: Colors.amber),

                const SizedBox(width: 4),

                Text(
                  (ownerProfile?.ratingAverage ?? 0).toStringAsFixed(1),
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
    );
  }
}
