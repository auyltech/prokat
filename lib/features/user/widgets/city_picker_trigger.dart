import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CityPickerTrigger extends ConsumerStatefulWidget {
  const CityPickerTrigger({super.key});

  @override
  ConsumerState<CityPickerTrigger> createState() => _CityPickerTriggerState();
}

class _CityPickerTriggerState extends ConsumerState<CityPickerTrigger> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(locationProvider);
    final selectedCity = locationState.city;

    return TextButton.icon(
      icon: Icon(
        LucideIcons.mapPin,
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
      label: Text(
        (selectedCity == null || selectedCity.isEmpty)
            ? l10n.selectCity
            : localizedCityName(selectedCity, l10n),
        style: TextStyle(color: theme.colorScheme.onPrimary),
      ),
      onPressed: () {
        CityPickerSheet.show(context: context);
      },
    );
  }
}
