import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/page_dots_indicator.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_image_actions_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerEquipmentImageHeader extends ConsumerStatefulWidget {
  final String equipmentId;
  final List<EquipmentImage> images;
  final String? legacyImageUrl;
  final bool canEditImages;

  const OwnerEquipmentImageHeader({
    super.key,
    required this.equipmentId,
    required this.images,
    required this.legacyImageUrl,
    this.canEditImages = true,
  });

  @override
  ConsumerState<OwnerEquipmentImageHeader> createState() =>
      _OwnerEquipmentImageHeaderState();
}

class _OwnerEquipmentImageHeaderState
    extends ConsumerState<OwnerEquipmentImageHeader> {
  final _pageController = PageController();
  final _picker = ImagePicker();

  int _currentIndex = 0;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  List<EquipmentImage> get _displayImages {
    final withUrl = widget.images
        .where((image) => image.imageUrl.trim().isNotEmpty)
        .toList();
    if (withUrl.isNotEmpty) return withUrl;

    final legacy = widget.legacyImageUrl?.trim() ?? '';
    if (legacy.isNotEmpty) {
      return [EquipmentImage(id: 'legacy', imageUrl: legacy, isPrimary: true)];
    }

    return const [];
  }

  @override
  void didUpdateWidget(covariant OwnerEquipmentImageHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    final count = _displayImages.length;
    if (_currentIndex >= count && count > 0) {
      setState(() => _currentIndex = count - 1);
    }
    if (count == 0 && _currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 3),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: _l10n.cropEquipmentPhoto,
            initAspectRatio: CropAspectRatioPreset.ratio4x3,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: _l10n.cropEquipmentPhoto,
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
          ),
        ],
      );

      if (cropped == null) return;

      final ok = await ref
          .read(equipmentMutationProvider.notifier)
          .uploadEquipmentImage(
            equipmentId: widget.equipmentId,
            imageFile: File(cropped.path),
          );

      if (!mounted) return;

      if (!ok) {
        final message =
            ref
                .read(equipmentMutationProvider.notifier)
                .getActionError("equipment:image:create")
                ?.message ??
            _l10n.failedToUploadPhoto;

        AppToast.show(message: message, type: AppToastType.error);
      } else {
        final count = _displayImages.length;
        if (count > 0) {
          unawaited(
            _pageController.animateToPage(
              count - 1,
              duration: AppDimens.defaultAnimationDuration,
              curve: Curves.easeOut,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('access_denied');
      AppToast.show(
        message: denied ? _l10n.mediaAccessDenied : _l10n.somethingWentWrong,
        type: AppToastType.error,
      );
    }
  }

  Future<void> _confirmAndDelete(EquipmentImage image) async {
    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: _l10n.deletePhotoQuestion,
      description: _l10n.deletePhotoConfirmation,
      primaryLabel: _l10n.delete,
      secondaryLabel: _l10n.cancel,
      isDestructivePrimary: true,
    );

    if (confirmed != true) return;

    final ok = await ref
        .read(equipmentMutationProvider.notifier)
        .deleteEquipmentImage(
          equipmentId: widget.equipmentId,
          imageId: image.id,
        );

    if (!mounted) return;

    if (!ok) {
      final id = image.id;

      final message =
          ref
              .read(equipmentMutationProvider.notifier)
              .getActionError("equipment:image:delete:$id")
              ?.message ??
          _l10n.failedToDeletePhoto;

      AppToast.show(message: message, type: AppToastType.error);
    }
  }

  Future<void> _setAsCover(EquipmentImage image) async {
    final ok = await ref
        .read(equipmentMutationProvider.notifier)
        .setPrimaryEquipmentImage(
          equipmentId: widget.equipmentId,
          imageId: image.id,
        );

    if (!mounted) return;

    if (!ok) {
      final id = image.id;

      final message =
          ref
              .read(equipmentMutationProvider.notifier)
              .getActionError("equipment:image:delete:$id")
              ?.message ??
          _l10n.failedToSetCoverPhoto;

      AppToast.show(message: message, type: AppToastType.error);
    }
  }

  Future<void> _openActionsSheet({
    required bool isBusy,
    required bool canAddMore,
    required EquipmentImage? current,
    required bool canSetCover,
    required bool canDelete,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final action = await EquipmentImageActionsSheet.show(
      context,
      canAddMore: canAddMore,
      isBusy: isBusy,
      canSetAsCover: canSetCover,
      canDelete: canDelete,
      limitMessage: canAddMore ? null : _l10n.maxPhotosReached,
    );

    if (!mounted || action == null) return;

    switch (action) {
      case EquipmentImageAction.gallery:
        await _pickAndUpload(ImageSource.gallery);
      case EquipmentImageAction.camera:
        await _pickAndUpload(ImageSource.camera);
      case EquipmentImageAction.setAsCover:
        if (current != null) await _setAsCover(current);
      case EquipmentImageAction.delete:
        if (current != null) await _confirmAndDelete(current);
    }

    if (mounted) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final state = ref.watch(equipmentMutationProvider);

    const actionId = "equipment:image";

    final isBusy =
        state.activeActions
            .where(
              (item) =>
                  item.id.contains(actionId) &&
                  item.status != MutationStatus.submitting,
            )
            .firstOrNull !=
        null;

    final images = _displayImages;
    final canAddMore = images.length < 5;
    final current = images.isNotEmpty ? images[_currentIndex] : null;

    final canDeleteCurrent =
        current != null &&
        images.isNotEmpty &&
        current.id.isNotEmpty &&
        current.id != 'legacy';

    final canSetCoverCurrent =
        current != null &&
        images.isNotEmpty &&
        current.id.isNotEmpty &&
        current.id != 'legacy' &&
        !(current.isPrimary ?? false);

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: images.isEmpty
              ? _emptyState(context)
              : PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final url = images[index].imageUrl;
                    return OptimizedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      maxCacheHeight: 900,
                      fallbackIcon: Icons.image_outlined,
                    );
                  },
                ),
        ),
        if (images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppDimens.s12$md,
            child: PageDotsIndicator(
              count: images.length,
              index: _currentIndex,
            ),
          ),

        if (widget.canEditImages)
          Positioned(
            right: AppDimens.s16$base,
            bottom: AppDimens.s16$base,
            child: Hero(
              tag: 'editEquipmentImages_${widget.equipmentId}',
              child: AppIconButton(
                icon: Icons.camera_alt,
                variant: AppIconButtonVariant.floating,
                tone: AppIconButtonTone.primary,
                onTap: () {
                  unawaited(
                    _openActionsSheet(
                      isBusy: isBusy,
                      canAddMore: canAddMore,
                      current: current,
                      canSetCover: canSetCoverCurrent,
                      canDelete: canDeleteCurrent,
                    ),
                  );
                },
              ),
            ),
          ),

        if (isBusy)
          Positioned.fill(
            child: Container(
              color: colorScheme.scrim.withValues(alpha: 0.15),
              alignment: Alignment.center,
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return const OwnerEquipmentPhotoPlaceholder();
  }
}

class OwnerEquipmentPhotoPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final bool compact;

  const OwnerEquipmentPhotoPlaceholder({
    super.key,
    this.width,
    this.height,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: width,
      height: height,
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppDimens.s08$sm : AppDimens.s32$xxl,
        vertical: compact ? AppDimens.inputHelperGap : AppDimens.s12$md,
      ),
      child: Text(
        l10n.equipmentPhotoRequiredPlaceholder,
        textAlign: TextAlign.center,
        maxLines: compact ? 4 : 3,
        overflow: TextOverflow.ellipsis,
        style:
            (compact
                    ? AppFonts.captionMedium(context)
                    : AppFonts.body16SemiBold(context))
                .copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.2,
                ),
      ),
    );
  }
}
