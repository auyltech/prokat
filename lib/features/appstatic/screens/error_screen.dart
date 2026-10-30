import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
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
    final flow = ProkatFlowScope.maybeOf(context);

    return Scaffold(
      backgroundColor: flow?.background ?? bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.circleAlert,
                    size: 80,
                    color: flow?.primary ?? accentColor,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    l10n.initializationError,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: flow?.title ?? Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.initializationErrorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: flow?.secondary ?? ghostGray,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  AppElevatedButton(
                    title: l10n.retryConnection,
                    onTap: () {
                      unawaited(ref.read(appStartupProvider.notifier).init());
                      context.go(AppRoutes.launch);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
