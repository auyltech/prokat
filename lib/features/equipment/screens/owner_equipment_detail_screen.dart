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
import 'package:prokat/features/equipment/widgets/owner/equipment_moderation_status_card.dart';
import 'package:prokat/features/equipment/widgets/owner/general_info_section.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_specs.dart';
import 'package:prokat/features/equipment/widgets/owner/registration_section.dart';
import 'package:prokat/features/owner/widgets/admin_comment_block.dart';
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
  String? _rejectedBaselineId;
  String? _rejectedBaselineFingerprint;

  @override
  void initState() {
    super.initState();

    unawaited(
      Future.microtask(() async {
        await ref.read(
          ownerEquipmentDetailsProvider(widget.equipmentId).future,
        );
        if (!mounted) return;

        await ref.read(categoriesProvider.notifier).refreshIfStale();
      }),
    );
  }

  void _rememberRejectedBaseline(Equipment equipment) {
    if (equipment.status != EquipmentStatus.rejected) {
      _rejectedBaselineId = null;
      _rejectedBaselineFingerprint = null;
      return;
    }
    if (_rejectedBaselineId == equipment.id &&
        _rejectedBaselineFingerprint != null) {
      return;
    }
    _rejectedBaselineId = equipment.id;
    _rejectedBaselineFingerprint = equipmentReviewFingerprint(equipment);
  }

  bool _hasChangedSinceRejection(Equipment equipment, bool anyDirty) {
    if (anyDirty) return true;
    final baseline = _rejectedBaselineFingerprint;
    if (baseline == null) return false;
    return equipmentReviewFingerprint(equipment) != baseline;
  }

  Future<void> _submitForReview(
    Equipment equipment,
    AppLocalizations l10n, {
    bool saveDirtyFirst = false,
  }) async {
    setState(() => _submitting = true);
    if (saveDirtyFirst) {
      final saveResult = await ref
          .read(ownerEquipmentEditorProvider(widget.equipmentId).notifier)
          .saveAll();
      if (!mounted) return;
      if (saveResult != SaveAllResult.success) {
        setState(() => _submitting = false);
        switch (saveResult) {
          case SaveAllResult.invalid:
            AppSnackBar.show(message: l10n.pleaseFillMissingInfo);
          case SaveAllResult.failed:
            AppSnackBar.show(
              message: l10n.couldNotSaveEquipment,
              isError: true,
            );
          case SaveAllResult.success:
            break;
        }
        return;
      }
    }
    if (!mounted) return;

    var latest = equipment;
    try {
      latest = await ref.read(
        ownerEquipmentDetailsProvider(widget.equipmentId).future,
      );
    } catch (_) {}
    if (!mounted) return;
    if (!equipmentHasImage(latest)) {
      setState(() => _submitting = false);
      AppSnackBar.show(message: l10n.equipmentSubmitPhotoRequired);
      return;
    }
    if (!isEquipmentReadyForReview(latest)) {
      setState(() => _submitting = false);
      AppSnackBar.show(message: l10n.pleaseCompleteRequiredFields);
      return;
    }

    final res = await ref
        .read(equipmentMutationProvider.notifier)
        .updateEquipmentStatus(latest.id, EquipmentStatus.created);
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
              _rememberRejectedBaseline(equipment);
              final editor = ref.watch(
                ownerEquipmentEditorProvider(widget.equipmentId),
              );
              final reviewUi = OwnerEquipmentReviewUi.from(
                status: equipment.status,
                anyDirty: editor.anyDirty,
              );
              final canAttemptResubmit =
                  reviewUi.showResubmit &&
                  !_submitting &&
                  _hasChangedSinceRejection(equipment, editor.anyDirty);

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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        CategorySelectorTile(
                          mode: CategorySheetMode.editEquipment,
                          selectedCategoryId: equipment.categoryId,
                        ),
                        if (equipment.isPendingReview ||
                            equipment.isRejected) ...[
                          const SizedBox(height: 16),
                          EquipmentModerationStatusCard(
                            status: equipment.status,
                          ),
                        ],
                        const SizedBox(height: 16),
                        GeneralInfoSection(equipment: equipment),
                        RegistrationSection(equipment: equipment),
                        OwnerEquipmentSpecs(equipment: equipment),
                        if (reviewUi.showSubmitForReview ||
                            reviewUi.showResubmit) ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.equipmentSubmitPhotoHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: reviewUi.showSubmitForReview
                                ? l10n.submitForReview
                                : l10n.resubmit,
                            onPressed: reviewUi.showSubmitForReview
                                ? (_submitting
                                      ? null
                                      : () => _submitForReview(
                                          equipment,
                                          l10n,
                                          saveDirtyFirst: editor.anyDirty,
                                        ))
                                : (canAttemptResubmit
                                      ? () => _submitForReview(
                                          equipment,
                                          l10n,
                                          saveDirtyFirst: editor.anyDirty,
                                        )
                                      : null),
                            isLoading: _submitting,
                          ),
                        ],
                        if (equipment.isRejected) ...[
                          const SizedBox(height: 16),
                          AdminCommentBlock(comment: equipment.adminComment),
                        ],
                        if (equipment.status != EquipmentStatus.booked) ...[
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
