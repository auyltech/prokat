import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
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
      // 1. Show the success notification dialog to the user
      _showSuccessAndLogoutDialog(context);
    } else if (mounted) {
      AppSnackBar.show(
        message: l10n.failedToRequestAccountDeletion,
        isError: true,
      );
    }
  }

  void _showSuccessAndLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    unawaited(
      showDialog(
        context: context,
        barrierDismissible:
            false, // Force them to explicitly tap "OK" to acknowledge the state
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: theme
                      .colorScheme
                      .primary, // Neutral or branding color for confirmation
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(l10n.requestReceived),
              ],
            ),
            content: Text(l10n.accountDeletionScheduledBody),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  // Close the dialog box view
                  Navigator.of(dialogContext).pop();

                  // 2. Perform the global logout sequence
                  // Replace this with your project's auth notifier reference (e.g., authProvider)
                  await ref.read(appStartupProvider.notifier).forceSignedOut();

                  // 3. Clear the navigation stack back to the authentication screen
                  if (context.mounted) {
                    unawaited(
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false),
                    );
                  }
                },
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeletionConfirmationDialog(BuildContext context) {
    unawaited(
      showDialog(
        context: context,
        builder: (dialogContext) {
          return const _DeleteAccountDialog();
        },
      ).then((confirmed) {
        if (confirmed == true && mounted) {
          unawaited(onSubmit());
        }
      }),
    );
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
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_forever_rounded),
          label: Text(l10n.initiateAccountDeletion),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _showDeletionConfirmationDialog(context),
        ),

        // Native spacing cushion at the base of scroll view
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  Future<void> _openHelp() async {
    final uri = Uri.parse(accountDeletionHelpUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    const confirmColor = Color(0xFFC62828);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      backgroundColor: colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.deleteAccountQuestion,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: Icon(Icons.close, color: colorScheme.onSurface),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      l10n.accountDeletionAccessStops,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.accountDeletionDataWithinDays,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => unawaited(_openHelp()),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: colorScheme.primary,
                        ),
                        child: Text(
                          l10n.learnMoreAboutDeletion,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: colorScheme.surface,
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(
                          color: colorScheme.onSurface.withValues(alpha: 0.28),
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.keepAccount),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.confirmAccountDeletion),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
