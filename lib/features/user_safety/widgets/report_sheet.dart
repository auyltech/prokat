import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/controls/selection/app_radio.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_area.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_bottom_sheet.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/features/user_safety/models/report_reason.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/state/user_safety_providers.dart';
import 'package:prokat/features/user_safety/user_safety_error_message.dart';
import 'package:prokat/features/user_safety/widgets/block_user_flow.dart';
import 'package:prokat/l10n/app_localizations.dart';

abstract final class ReportSheet {
  /// Report → toast → optional block prompt. Report itself never blocks.
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required ReportTarget target,
    required String counterpartUserId,
    String? chatId,
    bool offerBlock = true,
    VoidCallback? onBlocked,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final sent = await AppBottomSheet.show<bool>(
      context,
      title: l10n.reportReasonTitle,
      contentBuilder: (_) => ReportSheetContent(target: target),
    );
    if (sent != true || !context.mounted) return;

    AppToast.show(message: l10n.reportSentToast, type: AppToastType.success);
    if (!offerBlock) return;

    final block = await AppAlertBottomSheet.show(
      context,
      title: l10n.reportSentToast,
      description: l10n.reportSentBlockPrompt,
      primaryLabel: l10n.blockUserAction,
      secondaryLabel: l10n.notNow,
      isDestructivePrimary: true,
    );
    if (block != true || !context.mounted) return;

    final blocked = await confirmAndBlockUser(
      context,
      ref,
      userId: counterpartUserId,
      chatId: chatId,
    );
    if (blocked) onBlocked?.call();
  }
}

class ReportSheetContent extends ConsumerStatefulWidget {
  const ReportSheetContent({super.key, required this.target});

  final ReportTarget target;

  @override
  ConsumerState<ReportSheetContent> createState() => _ReportSheetContentState();
}

class _ReportSheetContentState extends ConsumerState<ReportSheetContent> {
  final _comment = TextEditingController();
  ReportReason? _reason;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n, ReportReason reason) {
    return switch (reason) {
      ReportReason.spam => l10n.reportReasonSpam,
      ReportReason.abuse => l10n.reportReasonAbuse,
      ReportReason.fraud => l10n.reportReasonFraud,
      ReportReason.other => l10n.reportReasonOther,
    };
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    final response = await ref
        .read(userSafetyControllerProvider)
        .report(widget.target, reason, _comment.text);
    if (!mounted) return;
    if (response.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _submitting = false);
    AppToast.show(
      message: userSafetyErrorMessage(l10n, response.errorCode),
      type: AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimens.s16$base,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final reason in ReportReason.values)
              AppRadioTile(
                key: ValueKey('report-reason-${reason.apiValue}'),
                value: _reason == reason,
                title: _label(l10n, reason),
                enabled: !_submitting,
                onChanged: (_) => setState(() => _reason = reason),
              ),
          ],
        ),
        AppTextArea(
          controller: _comment,
          hint: l10n.reportCommentHint,
          enabled: !_submitting,
          maxLength: 1000,
        ),
        AppElevatedButton(
          key: const ValueKey('report-submit'),
          title: l10n.reportSubmit,
          isLoading: _submitting,
          onTap: _reason == null || _submitting ? null : _submit,
        ),
      ],
    );
  }
}
