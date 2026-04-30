import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';

class AddressForm extends ConsumerStatefulWidget {
  const AddressForm({super.key});

  @override
  ConsumerState<AddressForm> createState() => AddressFormState();
}

class AddressFormState extends ConsumerState<AddressForm> {
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();
  final commentController = TextEditingController();

  double? latitude;
  double? longitude;

  void autofill(LocationSearchResult result) {
    streetController.text = result.street;
    cityController.text = result.city ?? "";
    countryController.text = result.country ?? "";

    latitude = result.latitude;
    longitude = result.longitude;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: streetController,
          decoration: const InputDecoration(labelText: "Street"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: cityController,
          decoration: const InputDecoration(labelText: "City"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: countryController,
          decoration: const InputDecoration(labelText: "Country"),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: commentController,
          decoration: const InputDecoration(labelText: "Comment"),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            final location = LocationModel(
              id: '',
              service: "EQUIPMENT",
              street: streetController.text,
              city: cityController.text,
              country: countryController.text,
              comment: commentController.text,
              instructions: null,
              latitude: latitude ?? 0,
              longitude: longitude ?? 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await ref.read(locationProvider.notifier).createLocation(location);

            if (mounted) Navigator.pop(context);
          },
          child: const Text("Save Location"),
        ),
      ],
    );
  }
}
