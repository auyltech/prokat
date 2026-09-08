import 'package:flutter/material.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserDisplayName extends StatelessWidget {
  final UserModel? user;

  const UserDisplayName({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final name = user?.displayName ?? '';
    final hasName = name.isNotEmpty;

    return Text(
      hasName ? name : l10n.nameNotSpecified,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: hasName ? FontWeight.w500 : FontWeight.w400,
        color: hasName
            ? null
            : theme.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
