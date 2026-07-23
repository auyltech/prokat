import 'package:flutter/material.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';

class OwnerProfileHeader extends StatelessWidget {
  final OwnerProfileModel? ownerProfile;
  const OwnerProfileHeader({super.key, required this.ownerProfile});

  @override
  Widget build(BuildContext context) {
    if (ownerProfile == null) return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.teal800,
        borderRadius: BorderRadius.circular(0),
      ),
      // Keep status bar area tinted correctly
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Avatar ──
          ProfileImagePicker(
            initialImageUrl: ownerProfile?.profileImageUrl ?? "",
          ),

          const SizedBox(height: 10),

          // ── Name ──
          const DisplayName(),

          // ── Rating + orders row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rate_rounded,
                size: 25,
                color: Color(0xFFF5C842),
              ),
              const SizedBox(width: 4),
              Text(
                (ownerProfile?.ratingAverage ?? 0).toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              // const SizedBox(width: 12),
              // Text(
              //   "${ownerProfileState.ownerProfile?.ratingCount ?? 0} ratings",
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
