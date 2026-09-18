import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EquipmentImageActionsSheet extends StatelessWidget {
  final bool canAddMore;
  final bool isBusy;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final VoidCallback? onSetAsCover;
  final VoidCallback? onDelete;
  final String? limitMessage;

  const EquipmentImageActionsSheet({
    super.key,
    required this.canAddMore,
    required this.isBusy,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onSetAsCover,
    required this.onDelete,
    required this.limitMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final disabledColor = colorScheme.onSurface.withValues(alpha: 0.38);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (limitMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.s16$base,
                  AppDimens.s12$md,
                  AppDimens.s16$base,
                  AppDimens.s04$xs,
                ),
                child: Text(
                  limitMessage!,
                  style: AppFonts.body14(context)
                      .copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: canAddMore ? null : disabledColor,
              ),
              title: Text(
                l10n.chooseFromGallery,
                style: AppFonts.body16(context)
                    .copyWith(color: canAddMore ? null : disabledColor),
              ),
              enabled: canAddMore && !isBusy,
              onTap: () {
                Navigator.of(context).pop();
                onPickFromGallery();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: canAddMore ? null : disabledColor,
              ),
              title: Text(
                l10n.takePhoto,
                style: AppFonts.body16(context)
                    .copyWith(color: canAddMore ? null : disabledColor),
              ),
              enabled: canAddMore && !isBusy,
              onTap: () {
                Navigator.of(context).pop();
                onPickFromCamera();
              },
            ),
            if (onSetAsCover != null)
              ListTile(
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
                onTap: () {
                  Navigator.of(context).pop();
                  onSetAsCover!();
                },
              ),
            if (onDelete != null)
              ListTile(
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
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
