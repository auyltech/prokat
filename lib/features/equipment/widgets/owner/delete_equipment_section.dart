import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class DeleteEquipmentSection extends ConsumerStatefulWidget {
  final String equipmentId;

  const DeleteEquipmentSection({super.key, required this.equipmentId});

  @override
  ConsumerState<DeleteEquipmentSection> createState() =>
      _DeleteEquipmentSectionState();
}

class _DeleteEquipmentSectionState
    extends ConsumerState<DeleteEquipmentSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final danger = colorScheme.error;
    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.7);

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: danger, size: 30),
              const SizedBox(width: 8),
              Text(
                l10n.dangerZone,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: danger.withValues(alpha: 0.85),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// DESCRIPTION
          Text(
            l10n.deleteEquipmentWarning,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ghostGray,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          /// DELETE BUTTON
          ActionButton.danger(
            label: l10n.deleteEquipment,
            icon: LucideIcons.trash,
            isLoading: ref
                .watch(equipmentMutationProvider)
                .isActionActive("equipment:delete:${widget.equipmentId}"),
            onPressed: () => unawaited(
              _confirmDelete(context, ref, widget.equipmentId, l10n),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String equipmentId,
  AppLocalizations l10n,
) async {
  FocusManager.instance.primaryFocus?.unfocus();

  final confirmed = await AppAlertBottomSheet.show(
    context,
    title: l10n.deleteEquipmentQuestion,
    description: l10n.deleteEquipmentConfirmation,
    primaryLabel: l10n.delete,
    secondaryLabel: l10n.cancel,
    isDestructivePrimary: true,
  );

  FocusManager.instance.primaryFocus?.unfocus();

  if (confirmed != true) return;

  final result = await ref
      .read(equipmentMutationProvider.notifier)
      .deleteEquipment(equipmentId);

  if (context.mounted) {
    context.pop();
  }

  AppSnackBar.show(
    message: result ? l10n.equipmentDeleted : l10n.failedToDeleteEquipment,
    isSuccess: result,
    isError: !result,
  );
}
