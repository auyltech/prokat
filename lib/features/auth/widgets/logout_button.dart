import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.logout,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        content: Text(
          l10n.logoutConfirmation,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(
              l10n.logout,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(appStartupProvider.notifier).forceSignedOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    return GestureDetector(
      onTap: authState.isLoading ? null : () => _confirmLogout(context, ref),
      child: AnimatedOpacity(
        opacity: authState.isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          // padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          // decoration: BoxDecoration(
          //   color: theme.colorScheme.surface,
          //   borderRadius: BorderRadius.circular(14),
          //   border: Border.all(color: theme.colorScheme.error),
          // ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 45,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: authState.isLoading
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.error,
                        )
                      : Icon(
                          LucideIcons.logOut,
                          color: theme.colorScheme.error,
                          size: 28,
                        ),
                ),
              ),

              const SizedBox(width: 20),

              Text(
                l10n.logout,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
