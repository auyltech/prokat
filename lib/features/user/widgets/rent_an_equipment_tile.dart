import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RentAnEquipmentTile extends ConsumerWidget {
  const RentAnEquipmentTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // Matches the top cards
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await ref.read(appStartupProvider.notifier).setClientMode();
            if (!context.mounted) return;
            context.go(AppRoutes.searchList);
          },
          child: Padding(
            // Expanded vertical padding provides a taller footprint
            padding: const EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: 18.0,
            ),
            child: Row(
              children: [
                // Expanded Icon Container Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3E8C).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 26, // Scaled up icon
                    color: Color(0xFF1B3E8C),
                  ),
                ),
                const SizedBox(width: 18),

                // Expanded Text Layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.rentAnEquipment,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 17, // Made slightly prominent
                          color: const Color(0xFF1B3E8C),
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ), // Expanded vertical text separation
                      Text(
                        'Switch back to client section dashboard',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Navigation Icon
                Icon(
                  Icons
                      .arrow_forward_ios_rounded, // Switched to a cleaner chevron
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
