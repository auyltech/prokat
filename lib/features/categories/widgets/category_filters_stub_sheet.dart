import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Placeholder filters sheet until catalog filters are implemented.
class CategoryFiltersStubSheet {
  static Future<void> show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.show<void>(
      context,
      title: l10n.categoryFilters,
      contentBuilder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppLabelButton(
                title: l10n.resetFilters,
                variant: AppLabelButtonVariant.text,
                tone: AppLabelButtonTone.neutral,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: AppDimens.s12$md),
            Text(
              l10n.categoryFiltersComingSoon,
              style: AppFonts.body14(context),
            ),
          ],
        );
      },
    );
  }
}
