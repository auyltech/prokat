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

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.storefront_outlined, size: 22),
        label: Text(
          l10n.rentAnEquipment,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1B3E8C),
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          backgroundColor: Colors.white, // deep blue from mockup
          foregroundColor: const Color(0xFF1B3E8C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () async {
          await ref.read(appStartupProvider.notifier).setClientMode();
          if (!context.mounted) return;
          context.go(AppRoutes.searchList);
        },
      ),
    );
  }
}
