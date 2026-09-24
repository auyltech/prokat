import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_outlined_button.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_bottom_sheet.dart';

/// Action-required alert on top of [AppBottomSheet].
///
/// Results: primary → `true`, secondary → `false`, barrier/drag dismiss → `null`.
abstract final class AppAlertBottomSheet {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? description,
    required String primaryLabel,
    String? secondaryLabel,
    bool isDestructivePrimary = false,
    bool isDismissible = true,
  }) {
    return AppBottomSheet.show<bool>(
      context,
      title: title,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      contentBuilder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppDimens.s24$xl,
          children: [
            if (description != null && description.isNotEmpty)
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppFonts.body16(sheetContext),
              ),
            Row(
              spacing: AppDimens.s12$md,
              children: [
                if (secondaryLabel != null)
                  Expanded(
                    child: AppOutlinedButton(
                      title: secondaryLabel,
                      onTap: () => Navigator.of(sheetContext).pop(false),
                    ),
                  ),
                Expanded(
                  child: AppElevatedButton(
                    title: primaryLabel,
                    style: isDestructivePrimary
                        ? AppElevatedButtonStyle.destructive
                        : AppElevatedButtonStyle.primary,
                    onTap: () => Navigator.of(sheetContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
