import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'address_search_suggestions.dart';

class AddressSearchBox extends ConsumerStatefulWidget {
  final Function(LocationSearchResult) onSelected;

  const AddressSearchBox({super.key, required this.onSelected});

  @override
  ConsumerState<AddressSearchBox> createState() => _AddressSearchBoxState();
}

class _AddressSearchBoxState extends ConsumerState<AddressSearchBox> {
  final controller = TextEditingController();
  Timer? debounce;

  void onSearchChanged(String value) {
    debounce?.cancel();

    debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(locationProvider.notifier).searchLocations(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(locationProvider);
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: "Search address",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        AddressSearchSuggestions(
          onSelected: (result) {
            controller.text = result.street;
            widget.onSelected(result);
          },
        ),
      ],
    );
  }
}
