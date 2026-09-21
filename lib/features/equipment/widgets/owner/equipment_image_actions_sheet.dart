import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

enum EquipmentImageAction { gallery, camera, setAsCover, delete }

class EquipmentImageActionsSheet extends StatelessWidget {
  final bool canAddMore;
  final bool isBusy;
  final bool canSetAsCover;
  final bool canDelete;

  const EquipmentImageActionsSheet({
    super.key,
    required this.canAddMore,
    required this.isBusy,
    required this.canSetAsCover,
    required this.canDelete,
  });

  static Future<EquipmentImageAction?> show(
    BuildContext context, {
    required bool canAddMore,
    required bool isBusy,
    required bool canSetAsCover,
    required bool canDelete,
    String? limitMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.show<EquipmentImageAction>(
      context,
      title: l10n.equipmentPhotoSheetTitle,
      subtitle: limitMessage,
      contentBuilder: (context) {
        return EquipmentImageActionsSheet(
          canAddMore: canAddMore,
          isBusy: isBusy,
          canSetAsCover: canSetAsCover,
          canDelete: canDelete,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final disabledColor = colorScheme.onSurface.withValues(alpha: 0.38);
    final canPick = canAddMore && !isBusy;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.sheetHorizontalPadding,
        0,
        AppDimens.sheetHorizontalPadding,
        MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.photo_library,
              color: canPick ? null : disabledColor,
            ),
            title: Text(
              l10n.chooseFromGallery,
              style: AppFonts.body16(context)
                  .copyWith(color: canPick ? null : disabledColor),
            ),
            enabled: canPick,
            onTap: () =>
                Navigator.of(context).pop(EquipmentImageAction.gallery),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.camera_alt,
              color: canPick ? null : disabledColor,
            ),
            title: Text(
              l10n.takePhoto,
              style: AppFonts.body16(context)
                  .copyWith(color: canPick ? null : disabledColor),
            ),
            enabled: canPick,
            onTap: () => Navigator.of(context).pop(EquipmentImageAction.camera),
          ),
          if (canSetAsCover)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.star_outline,
                color: isBusy ? disabledColor : null,
              ),
              title: Text(
                l10n.setAsCover,
                style: AppFonts.body16(context)
                    .copyWith(color: isBusy ? disabledColor : null),
              ),
              enabled: !isBusy,
              onTap: () =>
                  Navigator.of(context).pop(EquipmentImageAction.setAsCover),
            ),
          if (canDelete)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_outline,
                color: isBusy ? disabledColor : colorScheme.error,
              ),
              title: Text(
                l10n.deletePhoto,
                style: AppFonts.body16(
                  context,
                ).copyWith(color: isBusy ? disabledColor : colorScheme.error),
              ),
              enabled: !isBusy,
              onTap: () =>
                  Navigator.of(context).pop(EquipmentImageAction.delete),
            ),
        ],
      ),
    );
  }
}
