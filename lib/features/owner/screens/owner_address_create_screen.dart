import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import '../widgets/address_form.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/input_field.dart';

class OwnerAddressCreateScreen extends ConsumerStatefulWidget {
  final String service;
  final String? equipmentId;

  const OwnerAddressCreateScreen({
    super.key,
    required this.service,
    this.equipmentId,
  });

  @override
  ConsumerState<OwnerAddressCreateScreen> createState() =>
      _OwnerAddressCreateScreenState();
}

class _OwnerAddressCreateScreenState
    extends ConsumerState<OwnerAddressCreateScreen> {
  final formKey = GlobalKey<AddressFormState>();

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

  void onAddressSelected(LocationSearchResult result) {
    formKey.currentState?.autofill(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.service == "equipment"
                      ? "Add Location"
                      : "Add Address",
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
          ),

          Column(
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
              InputField(
                label: "City",
                controller: cityController,
                hint: "Atyrau",
              ),

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

                  final url = widget.service == "equipment"
                      ? "/owner/equipment/${widget.equipmentId}"
                      : "/equipment/${widget.equipmentId}";

                  if (res && mounted) context.push(url);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
