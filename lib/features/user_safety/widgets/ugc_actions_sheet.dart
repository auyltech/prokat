import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_outlined_button.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_bottom_sheet.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/widgets/block_user_flow.dart';
import 'package:prokat/features/user_safety/widgets/report_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

enum UgcAction { report, block, unblock }

abstract final class UgcActionsSheet {
  /// Report / Block (or Unblock) for content of another user.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String counterpartUserId,
    required String title,
    required ReportTarget reportTarget,
    String? chatId,
    bool isBlockedByMe = false,
    VoidCallback? onBlocked,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await AppBottomSheet.show<UgcAction>(
      context,
      title: title,
      contentBuilder: (sheetContext) => UgcActionsSheetContent(
        isBlockedByMe: isBlockedByMe,
        onSelected: (action) => Navigator.of(sheetContext).pop(action),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case UgcAction.report:
        await ReportSheet.show(
          context,
          ref,
          target: reportTarget,
          counterpartUserId: counterpartUserId,
          chatId: chatId,
          offerBlock: !isBlockedByMe,
          onBlocked: onBlocked,
        );
      case UgcAction.block:
        final blocked = await confirmAndBlockUser(
          context,
          ref,
          userId: counterpartUserId,
          chatId: chatId,
        );
        if (blocked) onBlocked?.call();
      case UgcAction.unblock:
        await unblockUserWithToast(
          l10n,
          ref,
          userId: counterpartUserId,
          chatId: chatId,
        );
    }
  }
}

class UgcActionsSheetContent extends StatelessWidget {
  const UgcActionsSheetContent({
    super.key,
    required this.isBlockedByMe,
    required this.onSelected,
  });

  final bool isBlockedByMe;
  final ValueChanged<UgcAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimens.s12$md,
      children: [
        AppOutlinedButton(
          key: const ValueKey('ugc-action-report'),
          title: l10n.reportAction,
          prefix: const Icon(LucideIcons.flag, size: AppDimens.s20$lg),
          onTap: () => onSelected(UgcAction.report),
        ),
        if (isBlockedByMe)
          AppOutlinedButton(
            key: const ValueKey('ugc-action-unblock'),
            title: l10n.unblockUserAction,
            prefix: const Icon(LucideIcons.userCheck, size: AppDimens.s20$lg),
            onTap: () => onSelected(UgcAction.unblock),
          )
        else
          AppOutlinedButton(
            key: const ValueKey('ugc-action-block'),
            title: l10n.blockUserAction,
            style: AppOutlinedButtonStyle.destructive,
            prefix: const Icon(LucideIcons.userX, size: AppDimens.s20$lg),
            onTap: () => onSelected(UgcAction.block),
          ),
      ],
    );
  }
}
