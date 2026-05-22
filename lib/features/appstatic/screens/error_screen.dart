import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/widgets/auth_button.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class ErrorScreen extends ConsumerWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bgColor = Color(0xFF121417);
    const ghostGray = Color(0x4DFFFFFF);
    const accentColor = Color(0xFF4E73DF);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sync_problem_rounded,
              size: 80,
              color: accentColor,
            ),
            const SizedBox(height: 32),
            Text(
              l10n.initializationError,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.initializationErrorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ghostGray, fontSize: 16),
            ),
            const SizedBox(height: 48),
            AuthButton(
              loading: false,
              text: l10n.retryConnection,
              loadingText: l10n.reconnecting,
              onPressed: () {
                ref.read(appStartupProvider.notifier).init();
                context.go(AppRoutes.launch);
              },
            ),
          ],
        ),
      ),
    );
  }
}
