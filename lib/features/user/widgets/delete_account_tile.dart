import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    unawaited(
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevents accidental closing during high-stakes actions
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(l10n.confirmDeletion),
              ],
            ),
            content: Text(l10n.accountDeletionConfirmationBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close dialog

                  unawaited(onSubmit());
                },
                child: Text(l10n.deleteAccount),
              ),
            ],
          );
        },
      ),
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
