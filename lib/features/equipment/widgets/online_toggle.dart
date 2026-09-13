import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OnlineToggle extends ConsumerWidget {
  final String id;
  final bool isVisible;
  final bool canShow;

  const OnlineToggle({
    super.key,
    required this.id,
    required this.isVisible,
    this.canShow = true,
  });

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
          isVisible && canShow ? l10n.equipmentShown : l10n.equipmentHidden,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isVisible && canShow
                ? colorScheme.primary
                : colorScheme.error,
          ),
        ),

        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isVisible && canShow,
            onChanged: !canShow
                ? (val) {
                    if (val) {
                      AppSnackBar.show(
                        message: l10n.equipmentNeedsTariffToShow,
                        isError: true,
                      );
                    }
                  }
                : (val) async {
                    final result = await ref
                        .read(equipmentMutationProvider.notifier)
                        .toggleEquipmentOnline(id, val);

                    if (context.mounted) {
                      AppSnackBar.show(
                        message: result
                            ? (val
                                  ? l10n.equipmentNowShown
                                  : l10n.equipmentNowHidden)
                            : l10n.failedToToggleEquipmentVisibility,
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
