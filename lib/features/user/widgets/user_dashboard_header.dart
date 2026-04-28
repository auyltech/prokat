import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/features/user/widgets/language_selector_tile.dart';

class UserDashboardHeader extends ConsumerStatefulWidget {
  const UserDashboardHeader({super.key});

  @override
  ConsumerState<UserDashboardHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends ConsumerState<UserDashboardHeader> {
  String selectedLanguage = 'EN';

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final profileImageUrl = userProfileState.userProfile?.profileImageUrl ?? "";
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final onPrimary = theme.colorScheme.onPrimary;
    final name = (userProfileState.userProfile?.displayName ?? '').isNotEmpty
        ? userProfileState.userProfile!.displayName
        : (userProfileState.userProfile?.phoneNumber ?? '').isNotEmpty
        ? formatPhoneNumber(userProfileState.userProfile!.phoneNumber!)
        : 'Hello!';

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
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
                    color: onPrimary, // Use onPrimary
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
                        color: onPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${(userProfileState.userProfile?.ratingStars ?? 0).toStringAsFixed(0)} reviews)',
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

          LanguageSelectorTile(
            value: selectedLanguage,
            onChanged: (lang) => setState(() => selectedLanguage = lang),
          ),
        ],
      ),
    );
  }
}
