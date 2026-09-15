import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/media/media_image_provider.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/user/widgets/user_display_name.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserInfoTile extends ConsumerWidget {
  final UserModel? user;
  final bool showPresence;

  const UserInfoTile({super.key, this.user, this.showPresence = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.surfaceContainer,
          backgroundImage: (user?.imageUrl ?? '').isNotEmpty
              ? mediaImageProvider(ref, user?.imageUrl)
              : null,
          onBackgroundImageError: (user?.imageUrl ?? '').isNotEmpty
              ? ignoreMediaImageLoadError
              : null,
          child: (user?.imageUrl ?? '').isNotEmpty
              ? null
              : ClipOval(
                  child: Transform.translate(
                    offset: const Offset(-6, -2),
                    child: Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.primary,
                      size: 60,
                    ),
                  ),
                ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(child: UserDisplayName(user: user)),
                  if (showPresence) ...[
                    const SizedBox(width: 8),
                    _OwnerPresenceChip(isOnline: user?.isAccountOnline == true),
                  ],
                ],
              ),

              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      '${user?.rating ?? 0} • ${l10n.ordersCount(user?.orderCount ?? 0)}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerPresenceChip extends StatelessWidget {
  const _OwnerPresenceChip({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final background = isOnline
        ? const Color(0xFF2D5A3F)
        : (isDark ? const Color(0xFF3A3F4A) : const Color(0xFFE5E7EB));
    final foreground = isOnline
        ? Colors.white
        : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOnline ? l10n.accountOnline : l10n.accountOffline,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
