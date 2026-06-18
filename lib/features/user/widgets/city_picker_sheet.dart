import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CityPickerSheet extends ConsumerStatefulWidget {
  final String? service;

  const CityPickerSheet({super.key, this.service});

  static Future<void> show({required BuildContext context, String? service}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return CityPickerSheet(service: service);
      },
    );
  }

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  Future<void> _onCitySelected(String city) async {
    ref.read(locationProvider.notifier).selectCity(city);

    if (mounted && context.canPop()) {
      context.pop();
    }

    if (widget.service == "main_screen") {
      // _updateFilters(context, {'city': city});
      return;
    } else if (widget.service == "equipment:create") {
      return;
    }

    final profile = ref.read(userProfileProvider).userProfile;

    if (profile != null) {
      await ref
          .read(userProfileProvider.notifier)
          .selectCityRegion(city, "No Region");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final selectedCity = ref.watch(locationProvider).city;
    final title = l10n?.selectCity ?? "Select City";

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              const SizedBox(height: 16),

              Text(title, style: theme.textTheme.titleLarge),

              const SizedBox(height: 12),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final isSelected = cities[index] == selectedCity;

                    return ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(cities[index]),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () => _onCitySelected(cities[index]),
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
