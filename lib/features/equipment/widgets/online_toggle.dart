import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OnlineToggle extends ConsumerWidget {
  final String id;
  final bool isVisible;

  const OnlineToggle({super.key, required this.id, required this.isVisible});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actionId = "equipment:update:$id:status";

    final isSubmitting = ref
        .watch(equipmentMutationProvider.notifier)
        .isActionActive(actionId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isSubmitting) const CircularProgressIndicator(),

        Text(
          isVisible ? l10n.online : l10n.offline,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isVisible ? colorScheme.primary : colorScheme.error,
          ),
        ),

        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isVisible,
            onChanged: (val) async {
              final result = await ref
                  .read(equipmentMutationProvider.notifier)
                  .toggleEquipmentOnline(id, val);

              if (context.mounted) {
                AppSnackBar.show(
                  message: result
                      ? l10n.equipmentIsNow(
                          val ? l10n.onlineStatus : l10n.offlineStatus,
                        )
                      : l10n.failedToToggleEquipment(
                          val ? l10n.onlineStatus : l10n.offlineStatus,
                        ),
                  isSuccess: result,
                  isError: !result,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
