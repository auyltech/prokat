import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_label_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_outlined_button.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_text_button.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_alert_bottom_sheet.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_bottom_sheet.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

const accountDeletionHelpUrl =
    'https://auyltech.kz/prokat/account-deletion.html';

class DeleteAccountTile extends ConsumerStatefulWidget {
  const DeleteAccountTile({super.key});

  @override
  ConsumerState<DeleteAccountTile> createState() => _DeleteAccountTileState();
}

class _DeleteAccountTileState extends ConsumerState<DeleteAccountTile>
    with AutomaticKeepAliveClientMixin {
  // Ensures the sliver view does not rebuild or reset state while scrolling
  @override
  bool get wantKeepAlive => true;

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final profileState = ref.read(clientProfileMutationProvider.notifier);

    final result = await profileState.deleteAccount();

    if (result && mounted) {
      await _showSuccessAndLogoutDialog(context);
    } else if (mounted) {
      AppToast.show(
        message: l10n.failedToRequestAccountDeletion,
        type: AppToastType.error,
      );
    }
  }

  Future<void> _showSuccessAndLogoutDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final acknowledged = await AppAlertBottomSheet.show(
      context,
      title: l10n.requestReceived,
      description: l10n.accountDeletionScheduledBody,
      primaryLabel: l10n.ok,
      isDismissible: false,
    );

    if (acknowledged != true) return;

    await ref.read(appStartupProvider.notifier).forceSignedOut();

    if (context.mounted) {
      unawaited(
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false),
      );
    }
  }

  Future<void> _showDeletionConfirmationDialog(BuildContext context) async {
    final confirmed = await _showDeleteAccountSheet(context);
    if (confirmed == true && mounted) {
      await onSubmit();
    }
  }

  Future<bool?> _showDeleteAccountSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.show<bool>(
      context,
      title: l10n.deleteAccountQuestion,
      contentBuilder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountDeletionAccessStops,
              textAlign: TextAlign.center,
              style: AppFonts.body16(sheetContext),
            ),
            const SizedBox(height: AppDimens.s12$md),
            Text(
              l10n.accountDeletionDataWithinDays,
              textAlign: TextAlign.center,
              style: AppFonts.body16(sheetContext),
            ),
            const SizedBox(height: AppDimens.s12$md),
            AppTextButton(
              title: l10n.learnMoreAboutDeletion,
              isExpanded: false,
              onTap: () => unawaited(_openAccountDeletionHelp()),
            ),
            const SizedBox(height: AppDimens.s20$lg),
            Row(
              spacing: AppDimens.s12$md,
              children: [
                Expanded(
                  child: AppElevatedButton.destructive(
                    title: l10n.confirmAccountDeletion,
                    onTap: () => Navigator.of(sheetContext).pop(true),
                  ),
                ),
                Expanded(
                  child: AppOutlinedButton(
                    title: l10n.keepAccount,
                    onTap: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAccountDeletionHelp() async {
    final uri = Uri.parse(accountDeletionHelpUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisAlignment:
          MainAxisAlignment.end, // Sticks control panel strictly to bottom
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Structural Divider
        Row(
          children: [
            Expanded(
              child: Divider(color: theme.colorScheme.error, thickness: 2),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.dangerZone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(color: theme.colorScheme.error, thickness: 2),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Compliance Info Card
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.permanentlyDeleteAccount,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.accountDeletionHoldDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer.withValues(
                      alpha: 0.8,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Production Danger Zone Trigger Button
        AppLabelButton(
          title: l10n.initiateAccountDeletion,
          onTap: () => unawaited(_showDeletionConfirmationDialog(context)),
          prefix: const Icon(Icons.delete_forever_rounded),
          isExpanded: true,
          size: AppLabelButtonSize.regular,
          variant: AppLabelButtonVariant.outlined,
          tone: AppLabelButtonTone.destructive,
        ),

        // Native spacing cushion at the base of scroll view
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}
