import 'package:flutter/material.dart';
import 'package:prokat/features/auth/models/user_model.dart';

class UserInfoTile extends StatelessWidget {
  final User? user;

  const UserInfoTile({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // if (user == null) return SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.surfaceContainer,
          child: Icon(
            Icons.person_rounded,
            color: theme.primaryColor,
            size: 22,
          ),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ?? "",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  '${user?.rating ?? 0} • ${user?.orderCount ?? 0} orders',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
