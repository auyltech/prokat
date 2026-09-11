import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

Future<void> continueGuestLogin(BuildContext context, {String? from}) async {
  if (from == null || from.isEmpty) {
    context.go(AppRoutes.login);
    return;
  }

  context.go(
    Uri(path: AppRoutes.login, queryParameters: {'from': from}).toString(),
  );
}

class LoginTile extends StatelessWidget {
  final String? afterLoginFrom;
  final String? label;

  const LoginTile({super.key, this.afterLoginFrom, this.label});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: () => continueGuestLogin(context, from: afterLoginFrom),
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
      label: Text(label ?? l10n.getStarted),
    );
  }
}
