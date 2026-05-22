import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  limitMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ListTile(
              leading: Icon(Icons.photo_library, color: canAddMore ? null : disabledColor),
              title: Text(
                l10n.chooseFromGallery,
                style: canAddMore ? null : TextStyle(color: disabledColor),
              ),
              enabled: canAddMore && !isBusy,
              onTap: () {
                Navigator.of(context).pop();
                onPickFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: canAddMore ? null : disabledColor),
              title: Text(
                l10n.takePhoto,
                style: canAddMore ? null : TextStyle(color: disabledColor),
              ),
              enabled: canAddMore && !isBusy,
              onTap: () {
                Navigator.of(context).pop();
                onPickFromCamera();
              },
            ),
            if (onSetAsCover != null)
              ListTile(
                leading: Icon(Icons.star_outline, color: isBusy ? disabledColor : null),
                title: Text(
                  l10n.setAsCover,
                  style: isBusy ? TextStyle(color: disabledColor) : null,
                ),
                enabled: !isBusy,
                onTap: () {
                  Navigator.of(context).pop();
                  onSetAsCover!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: isBusy ? disabledColor : colorScheme.error),
                title: Text(
                  l10n.deletePhoto,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isBusy ? disabledColor : colorScheme.error,
                  ),
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
