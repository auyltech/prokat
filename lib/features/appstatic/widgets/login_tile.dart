import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/post_login_location.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

Future<void> continueGuestLogin(
  BuildContext context,
  WidgetRef ref, {
  String? from,
}) async {
  final intent = from == AppRoutes.becomeOwner
      ? AppRoutes.becomeOwner
      : AppRoutes.clientProfile;
  ref.read(postLoginFromProvider.notifier).state = intent;
  final startup = ref.read(appStartupProvider.notifier);
  if (intent == AppRoutes.becomeOwner) {
    await startup.setOwnerMode();
  } else {
    await startup.setClientMode();
  }

  if (!context.mounted) return;

  if (from == null || from.isEmpty) {
    context.go(AppRoutes.login);
    return;
  }

  context.go(
    Uri(path: AppRoutes.login, queryParameters: {'from': from}).toString(),
  );
}

class LoginTile extends ConsumerWidget {
  final String? afterLoginFrom;
  final String? label;

  const LoginTile({super.key, this.afterLoginFrom, this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: () => continueGuestLogin(context, ref, from: afterLoginFrom),
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
