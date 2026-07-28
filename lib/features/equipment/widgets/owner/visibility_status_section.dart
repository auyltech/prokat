import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/widgets/online_toggle.dart';
import 'package:prokat/l10n/app_localizations.dart';

class VisibilityStatusSection extends ConsumerStatefulWidget {
  final Equipment? equipment;

  const VisibilityStatusSection({super.key, required this.equipment});

  @override
  ConsumerState<VisibilityStatusSection> createState() =>
      _VisibilityStatusSectionState();
}

class _VisibilityStatusSectionState
    extends ConsumerState<VisibilityStatusSection> {
  late bool _tempVisible;
  late EquipmentStatus _tempStatus;

  Future<void> submitForReview() async {
    final equipment = widget.equipment;
    if (equipment == null) return;

    final l10n = AppLocalizations.of(context)!;
    final res = await ref
        .read(equipmentMutationProvider.notifier)
        .updateEquipmentStatus(
          widget.equipment?.id ?? "",
          EquipmentStatus.created,
        );

    if (!mounted) return;

    AppSnackBar.show(
      message: res ? l10n.equipmentSubmittedForReview : l10n.failedToSubmit,
      isSuccess: res,
      isError: !res,
    );
  }

  bool hasText(String? value) => value?.trim().isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    _tempVisible = widget.equipment?.isVisible ?? false;
    _tempStatus = widget.equipment?.status ?? EquipmentStatus.draft;
  }

  bool get _isDirty =>
      (_tempVisible != widget.equipment?.isVisible) ||
      (_tempStatus != widget.equipment?.status);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final ghostGray = colorScheme.onSurface.withValues(alpha: 0.6);
    final accent = colorScheme.primary;
    final warning = theme.colorScheme.error;

    final equipment = widget.equipment;

    final hasImage =
        equipment != null &&
        (equipment.images.any((image) => hasText(image.imageUrl)) ||
            hasText(equipment.imageUrl));

    final hasDetails =
        equipment != null &&
        (hasText(equipment.categoryId) || hasText(equipment.category?.id)) &&
        hasText(equipment.name) &&
        hasText(equipment.model) &&
        hasText(equipment.plateNumber);

    final hasPrice =
        equipment != null && equipment.prices.any((entry) => entry.price > 0);

    final hasCity =
        equipment != null &&
        (hasText(equipment.city) || hasText(equipment.location?.city));

    final hasSpecs =
        equipment?.specs
            ?.where((spec) => spec.isRequired == true)
            .every((spec) => hasText(spec.value)) ??
        true;

    final hasData =
        equipment != null &&
        hasImage &&
        hasDetails &&
        hasPrice &&
        hasCity &&
        hasSpecs;

    final isModerated = equipment?.isModerated ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SectionTitle(title: l10n.status),

            if (_isDirty)
              FilledButton.icon(
                onPressed: equipment == null
                    ? null
                    : () async {
                        final res = await ref
                            .read(equipmentMutationProvider.notifier)
                            .toggleEquipmentOnline(
                              widget.equipment?.id ?? "",
                              widget.equipment?.isVisible ?? false,
                            );

                        if (res && context.mounted) {
                          AppSnackBar.show(
                            message: l10n.submittedForReview,
                            isSuccess: true,
                          );
                        }
                      },
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: Text(l10n.save),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              Icon(Icons.lock_outline_rounded, color: ghostGray, size: 18),
          ],
        ),

        SizedBox(height: 12),

        if (isModerated)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.availableForRent, style: theme.textTheme.bodyMedium),

              SizedBox(height: 8),

              if (equipment?.status == EquipmentStatus.available ||
                  equipment?.status == EquipmentStatus.accepted)
                OnlineToggle(
                  id: equipment?.id ?? "",
                  isVisible: equipment?.isVisible ?? false,
                ),

              SizedBox(height: 12),

              Text(l10n.operatingStatus, style: theme.textTheme.bodyMedium),

              SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      [
                        EquipmentStatus.available,
                        EquipmentStatus.booked,
                        EquipmentStatus.maintenance,
                      ].map((s) {
                        final isSelected = _tempStatus == s;
                        final isWarning = s == EquipmentStatus.maintenance;

                        final Color activeColor = isWarning ? warning : accent;

                        return GestureDetector(
                          onTap: () => setState(() => _tempStatus = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor.withValues(alpha: 0.12)
                                  : colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.05,
                                      ),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              s.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: isSelected ? activeColor : ghostGray,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ],
          ),

        if (!hasData) ...[
          Text(
            "*Please provide required information before submitting for review",
            style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
          ),
          SizedBox(height: 8),
        ],

        // if (isDraft)
        PrimaryButton(
          label: l10n.submitForReview,
          onPressed: hasData ? submitForReview : null,
          isLoading: equipment == null
              ? false
              : ref
                    .watch(equipmentMutationProvider)
                    .isActionActive("equipment:update:${equipment.id}:status"),
        ),
      ],
    );
  }
}
