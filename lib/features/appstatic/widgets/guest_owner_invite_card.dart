import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstatic/widgets/login_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class GuestOwnerInviteCard extends ConsumerWidget {
  const GuestOwnerInviteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      color: const Color(0xFF071D49),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.guestOwnerInviteTitle,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.guestOwnerInviteSubtitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(190),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          LoginTile(
            afterLoginFrom: AppRoutes.becomeOwner,
            label: l10n.receiveOrders,
            scrollToHeroIfNoCity: true,
          ),
        ],
      ),
    );
  }
}
