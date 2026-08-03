import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

class LogoTile extends StatelessWidget {
  const LogoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.go(AppRoutes.main),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Icon
          Container(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 60,
              height: 60,
            ),
          ),

          const SizedBox(width: 8),

          // 2. Prokat (Brand Name)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: theme.textTheme.displayLarge,
                  // TextStyle(
                  //   fontSize: 22,
                  //   fontWeight: FontWeight.w800,
                  //   letterSpacing: 0.04 * 22,
                  //   color: Color(0xFF1A1A2E),
                  // ),
                  children: [
                    TextSpan(text: 'PRO'),
                    TextSpan(
                      text: 'KAT',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),

              // 3. Slogan
              Text(
                AppLocalizations.of(context)!.equipmentRenting.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
