import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

class CityPickerSheet extends ConsumerStatefulWidget {
  final String title;
  final String? mode;
  final String? city;

  const CityPickerSheet({
    super.key,
    this.mode,
    this.title = 'Select City',
    this.city,
  });

  static Future<void> show({
    required BuildContext context,
    String? city,
    String? mode,
    String title = 'Select City',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return CityPickerSheet(title: title, city: city, mode: mode);
      },
    );
  }

  @override
  ConsumerState<CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<CityPickerSheet> {
  void _updateFilters(BuildContext context, Map<String, String?> newParams) {
    final router = GoRouter.of(context);
    final uri = router.routeInformationProvider.value.uri;

    final currentParams = Map<String, String>.from(uri.queryParameters);

    // Add/Update new parameters, remove if value is null
    newParams.forEach((key, value) {
      if (value == null) {
        currentParams.remove(key);
      } else {
        currentParams[key] = value;
      }
    });

    currentParams['page'] = '1';

    final newUri = uri.replace(
      queryParameters: currentParams.isEmpty ? null : currentParams,
    );

    print(newUri);

    context.go(newUri.toString());
  }

  Future<void> _onCitySelected(String city) async {
    print(widget.mode);

    if (widget.mode == "guest") {
      _updateFilters(context, {'city': city});
    } else {
      ref.read(locationProvider.notifier).selectCity(city);

      final profile = ref.read(userProfileProvider).userProfile;

      if (profile != null) {
        ref
            .read(userProfileProvider.notifier)
            .selectselectCityRegion(city, "No Region");
      }
    }

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCity = ref.watch(locationProvider).city;

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

              Text(widget.title, style: theme.textTheme.titleLarge),

              const SizedBox(height: 12),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = city == selectedCity;

                    return ListTile(
                      leading: const Icon(Icons.location_city),
                      title: Text(city),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () => _onCitySelected(city),
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
