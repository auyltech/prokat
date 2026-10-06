import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/features/user_safety/state/user_safety_providers.dart';
import 'package:prokat/features/user_safety/user_safety_error_message.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Confirm → block → toast. Returns true when the block was saved.
Future<bool> confirmAndBlockUser(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  String? chatId,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await AppAlertBottomSheet.show(
    context,
    title: l10n.blockUserConfirmTitle,
    description: l10n.blockUserConfirmBody,
    primaryLabel: l10n.blockUserAction,
    secondaryLabel: l10n.cancel,
    isDestructivePrimary: true,
  );
  if (confirmed != true) return false;

  final response = await ref
      .read(userSafetyControllerProvider)
      .blockUser(userId, chatId: chatId);
  if (response.success) {
    AppToast.show(message: l10n.userBlockedToast, type: AppToastType.success);
    return true;
  }
  AppToast.show(
    message: userSafetyErrorMessage(l10n, response.errorCode),
    type: AppToastType.error,
  );
  return false;
}

/// Unblock without confirmation. Returns true on success.
Future<bool> unblockUserWithToast(
  AppLocalizations l10n,
  WidgetRef ref, {
  required String userId,
  String? chatId,
}) async {
  final response = await ref
      .read(userSafetyControllerProvider)
      .unblockUser(userId, chatId: chatId);
  AppToast.show(
    message: response.success
        ? l10n.userUnblockedToast
        : userSafetyErrorMessage(l10n, response.errorCode),
    type: response.success ? AppToastType.success : AppToastType.error,
  );
  return response.success;
}
