import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserLocationTile extends ConsumerWidget {
  const UserLocationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final selectedCity = locationState.city;

    return GestureDetector(
      onTap: () {
        CityPickerSheet.show(context: context);
      },
      child: BaseTile(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.location_on, color: accent, size: 28),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCity != null && selectedCity != ""
                        ? l10n.city
                        : l10n.location,
                    style: theme.textTheme.labelMedium,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    selectedCity != null && selectedCity != ""
                        ? selectedCity
                        : l10n.selectCity,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedCity == null ? Colors.grey[600] : accent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            Icon(Icons.keyboard_arrow_down, size: 20, color: accent),
          ],
        ),
      ),
    );
  }
}
