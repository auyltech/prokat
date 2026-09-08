import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LoginTile extends StatelessWidget {
  const LoginTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: () => context.go(AppRoutes.login),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        iconAlignment: IconAlignment.end,
        iconColor: Colors.white,
        foregroundColor: Colors.white,
        splashFactory: InkRipple.splashFactory,
      ),
      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
      label: Text(l10n.getStarted),
    );
  }
}
