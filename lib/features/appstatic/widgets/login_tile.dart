import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LoginTile extends StatelessWidget {
  const LoginTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    const Color brightBlueButton = Color(0xFF2563EB);

    return // Login
    GestureDetector(
      onTap: () {
        context.push(AppRoutes.login);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: brightBlueButton,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.getStarted,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.login, size: 24, color: theme.colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }
}
