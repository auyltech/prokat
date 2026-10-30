import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

class LogoTile extends StatelessWidget {
  const LogoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      return GestureDetector(
        onTap: () => context.go(AppRoutes.main),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 64,
                height: 64,
                cacheWidth: 192,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'PRO'),
                          TextSpan(
                            text: 'KAT',
                            style: TextStyle(color: flow.primary),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.manropeFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: flow.title,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.equipmentRenting,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: flow.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.go(AppRoutes.main),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 60,
              height: 60,
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: theme.textTheme.displayLarge?.copyWith(height: 0.92),
                  children: [
                    const TextSpan(text: 'PRO'),
                    TextSpan(
                      text: 'KAT',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.equipmentRenting,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
