import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

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
    final profileImageUrl = userProfileState.userProfile?.profileImageUrl ?? "";
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.of(context).padding.top;

    final displayName = userProfileState.userProfile?.displayName;
    final name = (displayName ?? '').isNotEmpty ? displayName! : l10n.hello;

    final ratingStars = userProfileState.userProfile?.ratingStars ?? 0;

    return Container(
      padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006B54), Color(0xFF008E7D)],
        ),
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.push(AppRoutes.ownerProfile);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: colorScheme.primaryContainer,
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
                ),
              ],
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
                    color: theme.colorScheme.onPrimary,
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
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${ratingStars.toStringAsFixed(0)} ${l10n.reviews})',
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

          IconButton(
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
