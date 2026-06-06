import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserDashboardHeader extends ConsumerStatefulWidget {
  const UserDashboardHeader({super.key});

  @override
  ConsumerState<UserDashboardHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends ConsumerState<UserDashboardHeader> {
  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final profileImageUrl = userProfileState.userProfile?.profileImageUrl ?? "";
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final onPrimary = theme.colorScheme.onPrimary;
    final l10n = AppLocalizations.of(context)!;

    final name = (userProfileState.userProfile?.displayName ?? '').isNotEmpty
        ? userProfileState.userProfile!.displayName
        : (userProfileState.userProfile?.phoneNumber ?? '').isNotEmpty
        ? formatPhoneNumber(userProfileState.userProfile!.phoneNumber!)
        : l10n.hello;

    final ratingStars = userProfileState.userProfile?.ratingAverage ?? 0;

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: ClipOval(
                child: Image.network(
                  profileImageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.person, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: onPrimary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      ratingStars.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: onPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${ratingStars.toStringAsFixed(0)} ${l10n.reviews})',
                      style: TextStyle(
                        color: onPrimary.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
