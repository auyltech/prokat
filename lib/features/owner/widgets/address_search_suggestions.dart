import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AddressSearchSuggestions extends ConsumerWidget {
  final Function(LocationSearchResult) onSelected;

  const AddressSearchSuggestions({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(locationProvider).suggestions;
    final l10n = AppLocalizations.of(context)!;

    if (suggestions.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black12)],
      ),
      child: ListView.builder(
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final result = suggestions[index];

          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(
              result.streetLine(Localizations.localeOf(context).languageCode),
            ),
            subtitle: Text(
              formatCityCountry(
                l10n: l10n,
                city: locationCityLabel(
                  ref,
                  context,
                  city: result.city,
                  names: result.cityNames,
                ),
                country: result.labelCountry(
                  Localizations.localeOf(context).languageCode,
                ),
              ),
            ),
            onTap: () {
              ref.read(locationProvider.notifier).clearSuggestions();
              onSelected(result);
            },
          );
        },
      ),
    );
  }
}
