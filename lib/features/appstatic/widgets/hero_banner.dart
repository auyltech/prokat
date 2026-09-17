import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/appstatic/widgets/login_tile.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class HeroBanner extends ConsumerWidget {
  final String selectedCity;

  const HeroBanner({super.key, required this.selectedCity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color darkBlueBg = Color(0xFF071D49);
    final l10n = AppLocalizations.of(context)!;
    final hasSpecificCity = selectedCity.trim().isNotEmpty;

    return Container(
      color: darkBlueBg,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.heroPlatformTag,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(180),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.heroTitle,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          AppLabelButton(
            title: hasSpecificCity
                ? catalogCityLabelOf(ref, context, selectedCity)
                : l10n.allLocations,
            onTap: () => CityPickerSheet.show(
              context: context,
              service: CitySelectorService.guestcategory,
            ),
            prefix: const Icon(Icons.location_on_outlined),
            postfix: const Icon(Icons.keyboard_arrow_down),
            variant: AppLabelButtonVariant.soft,
            tone: AppLabelButtonTone.inverse,
          ),
          const SizedBox(height: 24),
          LoginTile(
            afterLoginFrom: AppRoutes.clientProfile,
            label: l10n.hireEquipment,
          ),
        ],
      ),
    );
  }
}
