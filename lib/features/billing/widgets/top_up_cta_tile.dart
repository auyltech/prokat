import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/constants/app_colors.dart' as legacy_colors;
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

class TopUpCtaTile extends StatelessWidget {
  const TopUpCtaTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            legacy_colors.AppColors.teal600,
            legacy_colors.AppColors.teal800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.add_moderator, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.runningLow,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  l10n.topUpMinutes,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          AppLabelButton(
            title: l10n.add,
            onTap: () {
              unawaited(context.push(AppRoutes.ownerPayment));
            },
            tone: AppLabelButtonTone.inverse,
          ),
        ],
      ),
    );
  }
}
