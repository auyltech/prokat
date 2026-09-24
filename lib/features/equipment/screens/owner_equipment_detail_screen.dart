import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_editor_provider.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/equipment_status_error_message.dart';
import 'package:prokat/features/equipment/utils/equipment_submit_readiness.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selection_sheet.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/equipment/widgets/owner/delete_equipment_section.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_moderation_status_card.dart';
import 'package:prokat/features/equipment/widgets/owner/general_info_section.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment_share/widgets/share_equipment_button.dart';
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
        // Always refetch: list can already show a newer moderation status while
        // this family cache still holds CREATED from a previous visit.
        await ref
            .read(ownerEquipmentDetailsProvider(widget.equipmentId).notifier)
            .refresh();
        if (!mounted) return;

        await ref.read(categoriesProvider.notifier).refreshIfStale();
      }),
    );
  }

  Future<bool> _confirmResubmit(
    Equipment equipment,
    AppLocalizations l10n,
  ) async {
    final comment = equipment.adminComment?.trim() ?? '';
    final remarks = comment.isEmpty ? l10n.statusRejectedNoComment : comment;

    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: l10n.resubmit,
      description: '${l10n.equipmentResubmitConfirmMessage}\n\n$remarks',
      primaryLabel: l10n.submit,
      secondaryLabel: l10n.cancel,
    );
    return confirmed == true;
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
            AppToast.show(message: l10n.pleaseFillMissingInfo);
          case SaveAllResult.failed:
            AppToast.show(
              message: l10n.couldNotSaveEquipment,
              type: AppToastType.error,
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
      AppToast.show(message: l10n.equipmentSubmitPhotoRequired);
      return;
    }
    if (!isEquipmentReadyForReview(latest)) {
      setState(() => _submitting = false);
      AppToast.show(message: l10n.pleaseCompleteRequiredFields);
      return;
    }

    final res = await ref
        .read(equipmentMutationProvider.notifier)
        .updateEquipmentStatus(latest.id, EquipmentStatus.created);
    if (!mounted) return;
    setState(() => _submitting = false);
    AppToast.show(
      message: res.success
          ? l10n.equipmentSubmittedForReview
          : equipmentStatusErrorMessage(
              l10n: l10n,
              errorCode: res.errorCode,
              fallback: l10n.failedToSubmit,
            ),
      type: res.success ? AppToastType.success : AppToastType.error,
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
          onRefresh: () => ref
              .read(ownerEquipmentDetailsProvider(widget.equipmentId).notifier)
              .refresh(),
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
              final reviewUi = OwnerEquipmentReviewUi.from(
                status: equipment.status,
                anyDirty: editor.anyDirty,
              );

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  Stack(
                    children: [
                      OwnerEquipmentImageHeader(
                        equipmentId: equipment.id,
                        images: equipment.images,
                        legacyImageUrl: equipment.imageUrl ?? '',
                        canEditImages: equipment.isDraft,
                      ),
                      Positioned(
                        top: AppDimens.s16$base,
                        right: AppDimens.s16$base,
                        child: ShareEquipmentButton(
                          equipment: equipment,
                          refreshOwnerDetails: true,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.s16$base,
                      AppDimens.s16$base,
                      AppDimens.s16$base,
                      AppDimens.s24$xl,
                    ),
                    child: Column(
                      children: [
                        CategorySelectorTile(
                          mode: CategorySheetMode.editEquipment,
                          selectedCategoryId: equipment.categoryId,
                        ),
                        if (equipment.isPendingReview ||
                            equipment.isRejected) ...[
                          const SizedBox(height: AppDimens.s16$base),
                          EquipmentModerationStatusCard(
                            status: equipment.status,
                            adminComment: equipment.adminComment,
                          ),
                        ],
                        const SizedBox(height: AppDimens.s16$base),
                        GeneralInfoSection(equipment: equipment),
                        RegistrationSection(equipment: equipment),
                        OwnerEquipmentSpecs(equipment: equipment),
                        if (reviewUi.showSubmitForReview ||
                            reviewUi.showResubmit) ...[
                          const SizedBox(height: AppDimens.s12$md),
                          Text(
                            l10n.equipmentSubmitPhotoHint,
                            style: AppFonts.caption(context),
                          ),
                          const SizedBox(height: AppDimens.s12$md),
                          AppElevatedButton(
                            title: reviewUi.showSubmitForReview
                                ? l10n.submitForReview
                                : l10n.resubmit,
                            onTap: _submitting
                                ? null
                                : () async {
                                    if (reviewUi.showResubmit) {
                                      final confirmed = await _confirmResubmit(
                                        equipment,
                                        l10n,
                                      );
                                      if (!confirmed || !mounted) return;
                                    }
                                    await _submitForReview(
                                      equipment,
                                      l10n,
                                      saveDirtyFirst: editor.anyDirty,
                                    );
                                  },
                            isLoading: _submitting,
                          ),
                        ],
                        if (equipment.status != EquipmentStatus.booked) ...[
                          const SizedBox(height: AppDimens.s20$lg),
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
