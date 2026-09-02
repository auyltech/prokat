import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_editor_provider.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/utils/equipment_submit_readiness.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/delete_equipment_section.dart';
import 'package:prokat/features/equipment/widgets/owner/general_info_section.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_specs.dart';
import 'package:prokat/features/equipment/widgets/owner/registration_section.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerEquipmentDetailScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const OwnerEquipmentDetailScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<OwnerEquipmentDetailScreen> createState() =>
      _OwnerEquipmentDetailScreenState();
}

class _OwnerEquipmentDetailScreenState
    extends ConsumerState<OwnerEquipmentDetailScreen> {
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    unawaited(
      Future.microtask(() async {
        await ref.read(
          ownerEquipmentDetailsProvider(widget.equipmentId).future,
        );

        await ref.read(categoriesProvider.notifier).refreshIfStale();
      }),
    );
  }

  Future<void> _saveAll(AppLocalizations l10n) async {
    final editor = ref.read(
      ownerEquipmentEditorProvider(widget.equipmentId).notifier,
    );
    final result = await editor.saveAll();
    if (!mounted) return;
    switch (result) {
      case SaveAllResult.success:
        AppSnackBar.show(message: l10n.equipmentUpdated, isSuccess: true);
      case SaveAllResult.invalid:
        AppSnackBar.show(message: l10n.pleaseFillMissingInfo);
      case SaveAllResult.failed:
        AppSnackBar.show(message: l10n.couldNotSaveEquipment, isError: true);
    }
  }

  Future<void> _submitForReview(
    Equipment equipment,
    AppLocalizations l10n,
  ) async {
    setState(() => _submitting = true);
    final res = await ref
        .read(equipmentMutationProvider.notifier)
        .updateEquipmentStatus(equipment.id, EquipmentStatus.created);
    if (!mounted) return;
    setState(() => _submitting = false);
    AppSnackBar.show(
      message: res ? l10n.equipmentSubmittedForReview : l10n.failedToSubmit,
      isSuccess: res,
      isError: !res,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final equipmentAsync = ref.watch(
      ownerEquipmentDetailsProvider(widget.equipmentId),
    );

    final bool isErrorState = equipmentAsync.hasError;

    return Scaffold(
      backgroundColor: isErrorState
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surface,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ownerEquipmentDetailsProvider(widget.equipmentId));
          },
          child: equipmentAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyStateTile(
              title: l10n.systemError,
              imageName: 'empty_error.png',
              subtitle: l10n.equipmentDataNotLocated,
            ),
            data: (equipment) {
              final editor = ref.watch(
                ownerEquipmentEditorProvider(widget.equipmentId),
              );
              final ready = isEquipmentReadyForReview(equipment);
              final showSaveAll = editor.anyDirty;
              final showSubmit = equipment.isDraft && !showSaveAll;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  OwnerEquipmentImageHeader(
                    equipmentId: equipment.id,
                    images: equipment.images,
                    legacyImageUrl: equipment.imageUrl ?? '',
                    canEditImages: equipment.isDraft,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      children: [
                        GeneralInfoSection(equipment: equipment),
                        CategorySelectorTile(
                          mode: CategorySheetMode.editEquipment,
                          selectedCategoryId: equipment.categoryId,
                        ),
                        const SizedBox(height: 12),
                        RegistrationSection(equipment: equipment),
                        OwnerEquipmentSpecs(equipment: equipment),
                        if (showSaveAll) ...[
                          const SizedBox(height: 8),
                          PrimaryButton(
                            label: l10n.saveAll,
                            isLoading: editor.anySaving,
                            onPressed: editor.anySaving
                                ? null
                                : () => _saveAll(l10n),
                          ),
                        ] else if (showSubmit) ...[
                          const SizedBox(height: 8),
                          if (!ready)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l10n.pleaseCompleteRequiredFields,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          PrimaryButton(
                            label: equipment.status == EquipmentStatus.draft
                                ? l10n.submitForReview
                                : l10n.resubmit,
                            onPressed: ready && !_submitting
                                ? () => _submitForReview(equipment, l10n)
                                : null,
                            isLoading: _submitting,
                          ),
                        ],
                        if (equipment.status == EquipmentStatus.draft) ...[
                          const SizedBox(height: 20),
                          DeleteEquipmentSection(equipmentId: equipment.id),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
