import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

enum CitySelectorService {
  guestcategory,
  createequipment,
  clientcity,
  demandsurvey,
  becomeowner,
  ownerprofile,
}

bool cityPickerIncludesAllCities(CitySelectorService? service) {
  return service == null ||
      service == CitySelectorService.guestcategory ||
      service == CitySelectorService.clientcity;
}

List<String> cityPickerOptions({
  required Iterable<String> cityKeys,
  CitySelectorService? service,
}) {
  final keys = cityKeys.toList(growable: false);
  if (cityPickerIncludesAllCities(service)) {
    return ['', ...keys];
  }
  return keys;
}

class CityPickerSheet extends ConsumerStatefulWidget {
  final CitySelectorService? service;
  final String? highlightedCity;
  final ScrollController scrollController;

  const CityPickerSheet({
    super.key,
    this.service,
    this.highlightedCity,
    required this.scrollController,
  });

  static Future<String?> show({
    required BuildContext context,
    CitySelectorService? service,
    String? highlightedCity,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return AppBottomSheet.showScrollable<String>(
      context,
      title: l10n.selectCity,
      initialChildSize: 0.4,
      maxChildSize: 0.4,
      minChildSize: 0.3,
      headerBuilder: (_) => const SizedBox.shrink(),
      footerBuilder: (_) => const SizedBox.shrink(),
      scrollableListBuilder: (context, controller) {
        return CityPickerSheet(
          service: service,
          highlightedCity: highlightedCity,
          scrollController: controller,
        );
      },
    );
  }

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  Future<String?> _onCitySelected(String city) async {
    final persistSessionCity =
        widget.service != CitySelectorService.becomeowner &&
        widget.service != CitySelectorService.ownerprofile;
    if (persistSessionCity) {
      ref.read(locationProvider.notifier).selectCity(city);
    }

    if (mounted && context.canPop()) {
      context.pop(city);
    }

    if (widget.service == CitySelectorService.guestcategory ||
        widget.service == CitySelectorService.createequipment ||
        widget.service == CitySelectorService.demandsurvey ||
        widget.service == CitySelectorService.becomeowner ||
        widget.service == CitySelectorService.ownerprofile) {
      return city;
    }

    final profile = ref.read(clientProfileProvider).userProfile;

    if (profile != null) {
      unawaited(
        ref
            .read(clientProfileMutationProvider.notifier)
            .selectCityRegion(city: city),
      );
    }

    return city;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;

    final selectedCity =
        widget.highlightedCity ?? ref.watch(locationProvider).city;
    final options = cityPickerOptions(
      cityKeys: catalogCityKeys(catalog),
      service: widget.service,
    );

    return ListView.separated(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        AppDimens.sheetHorizontalPadding,
        0,
        AppDimens.sheetHorizontalPadding,
        AppDimens.sheetBottomPadding + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: options.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final option = options[index];
        final isAllCities = option.trim().isEmpty;
        final isSelected = isSameCity(option, selectedCity);

        return ListTile(
          leading: Icon(
            isAllCities ? Icons.public_outlined : Icons.location_city,
          ),
          title: Text(
            isAllCities
                ? l10n.allLocations
                : catalogCityLabel(
                    city: option,
                    languageCode: locale,
                    catalog: catalog,
                    fallback: (city) => localizedCityName(city, l10n),
                  ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
              : null,
          onTap: () async => await _onCitySelected(option),
        );
      },
    );
  }
}
