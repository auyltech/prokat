import 'package:flutter/material.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/user/widgets/user_display_name.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserInfoTile extends StatelessWidget {
  final UserModel? user;

  const UserInfoTile({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.surfaceContainer,
          backgroundImage: (user?.imageUrl ?? '').isNotEmpty
              ? NetworkImage(user?.imageUrl ?? "")
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
              UserDisplayName(user: user),

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
