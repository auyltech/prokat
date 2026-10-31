import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/features/user/widgets/display_name.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientProfileHeader extends StatelessWidget {
  final UserProfileModel? userProfile;

  const ClientProfileHeader({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final flow = ProkatFlowScope.maybeOf(context);
    final rating = Text(
      (userProfile?.ratingAverage ?? 0) <= 0
          ? l10n.listingNoReviews
          : (userProfile?.ratingAverage ?? 0).toStringAsFixed(1),
      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
    );
    final orders = Text(
      "· ${l10n.ordersCount(userProfile?.orderCount ?? 0)}",
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );

    return Container(
      width: double.infinity,
      // margin: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: flow == null
              ? const [
                  Color(0xFF002C63), // Your original primary color
                  Color(0xFF004B87), // A lighter blue for the gradient effect
                ]
              : [
                  Color.lerp(flow.filledPrimary, Colors.black, .25)!,
                  flow.filledPrimary,
                ],
        ),
        borderRadius: flow == null
            ? null
            : const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      // SafeArea prevents content from clipping into the status bar notch
      child: SafeArea(
        bottom: flow == null,
        child: Padding(
          padding: flow == null
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: flow == null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [NotificationBadge(color: Colors.white)],
              // ),
              const SizedBox(height: 40),

              ProfileImagePicker(
                initialImageUrl: userProfile?.profileImageUrl ?? "",
                mode: AppMode.clientMode,
                radius: flow == null ? 80 : 56,
              ),

              const SizedBox(height: 12),

              const DisplayName(),

              if (flow != null)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    const Icon(LucideIcons.star, size: 20, color: Colors.amber),
                    rating,
                    orders,
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.star, size: 20, color: Colors.amber),

                    const SizedBox(width: 6),

                    rating,

                    const SizedBox(width: 8),

                    orders,
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
