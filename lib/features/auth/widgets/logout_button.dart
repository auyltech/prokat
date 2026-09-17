import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../../auth/providers/auth_provider.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);

    final confirm = await AppAlertBottomSheet.show(
      context,
      title: l10n.logout,
      description: l10n.logoutConfirmation,
      primaryLabel: l10n.logout,
      secondaryLabel: l10n.cancel,
      isDestructivePrimary: true,
    );

    if (confirm != true) return;

    final signOut = ref.read(appStartupProvider.notifier).forceSignedOut();

    // Leave the authenticated shell immediately. The profile context may be
    // disposed while the remote/local logout sequence is still completing.
    router.go(AppRoutes.main);
    await signOut;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    return AppOutlinedButton.destructive(
      title: l10n.logout,
      onTap: authState.isLoading ? null : () => _confirmLogout(context, ref),
      isLoading: authState.isLoading,
      isExpanded: true,
      prefix: const Icon(LucideIcons.logOut),
    );
  }
}
