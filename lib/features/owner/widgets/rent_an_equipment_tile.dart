import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/profile_accent_cta.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RentAnEquipmentTile extends ConsumerWidget {
  const RentAnEquipmentTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileAccentCta(
      leading: ProfileAccentCta.truckSearch(),
      title: l10n.rentAnEquipment,
      subtitle: l10n.rentAnEquipmentSubtitle,
      onTap: () async {
        await ref.read(appStartupProvider.notifier).setClientMode();
        if (!context.mounted) return;
        context.go(AppRoutes.clientProfile);
      },
    );
  }
}
