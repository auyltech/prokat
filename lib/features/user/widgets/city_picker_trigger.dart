import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
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
    final cityLabel = (selectedCity == null || selectedCity.isEmpty)
        ? l10n.allLocations
        : catalogCityLabelOf(ref, context, selectedCity);
    void openPicker() => unawaited(
      CityPickerSheet.show(
        context: context,
        service: CitySelectorService.clientcity,
      ),
    );
    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      return Tooltip(
        message: cityLabel,
        child: Material(
          color: flow.primarySoft,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: openPicker,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: BoxConstraints(
                minHeight: 44,
                maxWidth: (MediaQuery.sizeOf(context).width * 0.36)
                    .clamp(96.0, 150.0)
                    .toDouble(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.mapPin, size: 18, color: flow.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      cityLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: flow.title,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppLabelButton(
      title: cityLabel,
      prefix: const Icon(LucideIcons.mapPin),
      variant: AppLabelButtonVariant.text,
      tone: AppLabelButtonTone.neutral,
      onTap: openPicker,
    );
  }
}
