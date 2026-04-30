import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';

class AddressSearchSuggestions extends ConsumerWidget {
  final Function(LocationSearchResult) onSelected;

  const AddressSearchSuggestions({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(locationProvider).suggestions;

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
            title: Text(result.street),
            subtitle: Text("${result.city}, ${result.country}"),
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
