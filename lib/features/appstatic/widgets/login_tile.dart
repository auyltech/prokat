import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstatic/state/guest_city_prompt.dart';
import 'package:prokat/features/appstatic/state/guest_landing_scroll.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

Future<void> continueGuestLogin(
  BuildContext context,
  WidgetRef ref, {
  String? from,
  bool scrollToHeroIfNoCity = false,
}) async {
  final city = (ref.read(locationProvider).city ?? '').trim();
  if (city.isEmpty) {
    if (scrollToHeroIfNoCity) {
      await ref.read(guestLandingScrollProvider).scrollToHero();
    }
    if (!context.mounted) return;
    ref.read(guestCityPromptProvider.notifier).prompt();
    return;
  }

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
  final bool scrollToHeroIfNoCity;

  const LoginTile({
    super.key,
    this.afterLoginFrom,
    this.label,
    this.scrollToHeroIfNoCity = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return FilledButton.icon(
      onPressed: () => unawaited(
        continueGuestLogin(
          context,
          ref,
          from: afterLoginFrom,
          scrollToHeroIfNoCity: scrollToHeroIfNoCity,
        ),
      ),
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
