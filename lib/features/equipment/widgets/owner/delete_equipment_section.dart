import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, ref, widget.equipmentId, l10n),
              icon: const Icon(Icons.delete_outline_outlined, size: 30),
              label: Text(
                l10n.deleteEquipment,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: BorderSide(color: danger.withValues(alpha: 0.4)),
                backgroundColor: danger.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String equipmentId,
  AppLocalizations l10n,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// DRAG HANDLE
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_sweep_rounded,
                color: colorScheme.error,
                size: 30,
              ),

              const SizedBox(width: 12),

              Text(
                l10n.deleteEquipmentQuestion,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            l10n.deleteEquipmentConfirmation,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// DELETE BUTTON
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await ref
                      .read(equipmentProvider.notifier)
                      .deleteEquipment(equipmentId);

                  if (context.mounted && context.canPop()) context.pop();

                  if (context.mounted) {
                    context.pop();
                  }
                },
                child: Text(
                  l10n.delete,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 12),

              /// CANCEL
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
