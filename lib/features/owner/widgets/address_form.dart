import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
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
        InputField(
          label: "House / Building / Staircase",
          controller: commentController,
          hint: "My House",
        ),
        InputField(
          label: "Street",
          controller: streetController,
          hint: "Stapayeva 123",
        ),
        InputField(label: "City", controller: cityController, hint: "Atyrau"),

        const SizedBox(height: 24),

        PrimaryButton(
          label: "Save Location",
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

            final res = await ref
                .read(locationProvider.notifier)
                .createLocation(location);

            if (res && mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
