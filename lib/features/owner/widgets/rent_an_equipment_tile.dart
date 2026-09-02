import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RentAnEquipmentTile extends ConsumerWidget {
  const RentAnEquipmentTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await ref.read(appStartupProvider.notifier).setClientMode();
          if (!context.mounted) return;
          context.go(AppRoutes.clientProfile);
        },
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 18, 50),
          color: Colors.blue.shade800.withValues(alpha: 0.15),
          child: Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 40,
                color: Color(0xFF1B3E8C),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.rentAnEquipment,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: const Color(0xFF1B3E8C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.switchBackToClient,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                LucideIcons.chevronRight,
                color: theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
