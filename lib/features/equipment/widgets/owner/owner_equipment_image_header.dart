import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_image_actions_sheet.dart';
import 'dart:io';

class OwnerEquipmentImageHeader extends ConsumerStatefulWidget {
  final String equipmentId;
  final List<EquipmentImage> images;
  final String? legacyImageUrl;

  const OwnerEquipmentImageHeader({
    super.key,
    required this.equipmentId,
    required this.images,
    required this.legacyImageUrl,
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

  List<EquipmentImage> get _displayImages {
    if (widget.images.isNotEmpty) return widget.images;

    final legacy = widget.legacyImageUrl;
    if (legacy != null && legacy.isNotEmpty) {
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
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
    );

    if (picked == null) return;

    final ok = await ref
        .read(equipmentProvider.notifier)
        .uploadEquipmentImage(
          equipmentId: widget.equipmentId,
          imageFile: File(picked.path),
        );

    if (!mounted) return;

    if (!ok) {
      final state = ref.read(equipmentProvider);
      final message =
          state.imageActionErrorByEquipmentId[widget.equipmentId] ??
          'Failed to upload photo';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      final count = _displayImages.length;
      if (count > 0) {
        _pageController.animateToPage(
          count - 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _confirmAndDelete(EquipmentImage image) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await ref
        .read(equipmentProvider.notifier)
        .deleteEquipmentImage(
          equipmentId: widget.equipmentId,
          imageId: image.id,
        );

    if (!mounted) return;

    if (!ok) {
      final state = ref.read(equipmentProvider);
      final message =
          state.imageActionErrorByEquipmentId[widget.equipmentId] ??
          'Failed to delete photo';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _setAsCover(EquipmentImage image) async {
    final ok = await ref
        .read(equipmentProvider.notifier)
        .setPrimaryEquipmentImage(
          equipmentId: widget.equipmentId,
          imageId: image.id,
        );

    if (!mounted) return;

    if (!ok) {
      final state = ref.read(equipmentProvider);
      final message =
          state.imageActionErrorByEquipmentId[widget.equipmentId] ??
          'Failed to set cover photo';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openActionsSheet({
    required bool isBusy,
    required bool canAddMore,
    required EquipmentImage? current,
    required bool canSetCover,
    required bool canDelete,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return EquipmentImageActionsSheet(
          canAddMore: canAddMore,
          isBusy: isBusy,
          limitMessage: canAddMore ? null : 'Max 5 photos reached',
          onPickFromGallery: () => _pickAndUpload(ImageSource.gallery),
          onPickFromCamera: () => _pickAndUpload(ImageSource.camera),
          onSetAsCover: canSetCover ? () => _setAsCover(current!) : null,
          onDelete: canDelete ? () => _confirmAndDelete(current!) : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final state = ref.watch(equipmentProvider);
    final isBusy = state.imageActionInProgressEquipmentIds.contains(
      widget.equipmentId,
    );

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
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      memCacheHeight: 600,
                      placeholder: (_, __) => Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                      errorWidget: (_, __, ___) => _emptyState(context),
                    );
                  },
                ),
        ),

        if (images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: _DotsIndicator(count: images.length, index: _currentIndex),
          ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'editEquipmentImages_${widget.equipmentId}',
            onPressed: () => _openActionsSheet(
              isBusy: isBusy,
              canAddMore: canAddMore,
              current: current,
              canSetCover: canSetCoverCurrent,
              canDelete: canDeleteCurrent,
            ),
            child: const Icon(Icons.camera_alt),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'No photos yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;

  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final active = colorScheme.onSurface.withValues(alpha: 0.9);
    final inactive = colorScheme.onSurface.withValues(alpha: 0.35);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 10 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? active : inactive,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}
