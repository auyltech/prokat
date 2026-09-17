import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
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
    final l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(locationProvider);
    final selectedCity = locationState.city;

    return AppLabelButton(
      title: (selectedCity == null || selectedCity.isEmpty)
          ? l10n.allLocations
          : catalogCityLabelOf(ref, context, selectedCity),
      prefix: const Icon(LucideIcons.mapPin),
      variant: AppLabelButtonVariant.text,
      tone: AppLabelButtonTone.neutral,
      onTap: () {
        unawaited(
          CityPickerSheet.show(
            context: context,
            service: CitySelectorService.clientcity,
          ),
        );
      },
    );
  }
}
