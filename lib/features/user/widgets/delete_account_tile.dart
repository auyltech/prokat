import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

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
    final profileState = ref.read(userProfileProvider.notifier);

    final result = await profileState.deleteAccount();

    if (result && mounted) {
      // 1. Show the success notification dialog to the user
      _showSuccessAndLogoutDialog(context);
    } else if (mounted) {
      AppSnackBar.show(
        message: 'Failed to request account deletion. Please try again.',
        isError: true,
      );
    }
  }

  void _showSuccessAndLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);

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
              const Text('Request Received'),
            ],
          ),
          content: const Text(
            'Your account is now safely scheduled for deletion.\n\n'
            'You will be signed out immediately. Remember that logging back into '
            'the app with this phone number within the next 14 days will automatically '
            'restore your data and cancel this request.',
          ),
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
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletionConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);

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
              const Text('Confirm Deletion'),
            ],
          ),
          content: const Text(
            'Your account will immediately enter a "Pending Deletion" status.\n\n'
            'To protect against accidental data loss, all data will be permanently '
            'erased in exactly 14 days. Logging back into your account before '
            'this period ends will cancel the deletion request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
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

                onSubmit();
              },
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

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
            SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Danger Zone',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Divider(color: theme.colorScheme.error, thickness: 2),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Compliance Info Card
        Card(
          elevation: 0,
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
                      'Permanently Delete Account',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'This actions kicks off a 14-day hold window. If you do not change your mind '
                  'and opt out by logging back into your profile before this period lapses, '
                  'all personal records, history, cloud files, and purchases will be completely erased.',
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
          label: const Text('Initiate Account Deletion'),
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
