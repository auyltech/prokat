import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/core/utils/localized_city.dart';
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

class CityPickerSheet extends ConsumerStatefulWidget {
  final CitySelectorService? service;
  final String? highlightedCity;

  const CityPickerSheet({super.key, this.service, this.highlightedCity});

  static Future<String?> show({
    required BuildContext context,
    CitySelectorService? service,
    String? highlightedCity,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return CityPickerSheet(
          service: service,
          highlightedCity: highlightedCity,
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
      ref
          .read(clientProfileMutationProvider.notifier)
          .selectCityRegion(city: city);
    }

    return city;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final selectedCity =
        widget.highlightedCity ?? ref.watch(locationProvider).city;
    final title = l10n.selectCity;
    final allLocationsLabel = l10n.allLocations;

    final cityOptions = widget.service == CitySelectorService.guestcategory
        ? ["", ...cities]
        : cities;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(title, style: theme.textTheme.titleLarge),

              const SizedBox(height: 12),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cityOptions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = cityOptions[index];
                    final isSelected = option.isEmpty
                        ? (selectedCity == null || selectedCity.isEmpty)
                        : isSameCity(option, selectedCity);

                    return ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(
                        option.isEmpty
                            ? allLocationsLabel
                            : localizedCityName(option, l10n),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () async => await _onCitySelected(option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
