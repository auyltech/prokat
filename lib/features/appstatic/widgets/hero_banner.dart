import 'package:flutter/material.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/features/appstatic/widgets/login_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class HeroBanner extends StatelessWidget {
  final String selectedCity;

  const HeroBanner({super.key, required this.selectedCity});

  @override
  Widget build(BuildContext context) {
    const Color darkBlueBg = Color(0xFF071D49);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: darkBlueBg,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Middle Section: Headline Text
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
          const Text(
            "Find & rent\nequipment\nin minutes",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Location Dropdown Selector
          GestureDetector(
            onTap: () =>
                CityPickerSheet.show(context: context, service: "main_screen"),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    selectedCity.isNotEmpty ? selectedCity : l10n.allLocations,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          LoginTile(),

          // "Get Started" Call to Action Button
          const SizedBox(height: 24),
          // Bottom Section: Decorative Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 40,
                color: Colors.white.withAlpha(40),
              ),
              const SizedBox(width: 40),
              Icon(
                Icons.local_shipping,
                size: 40,
                color: Colors.white.withAlpha(40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
