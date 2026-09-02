import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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

  LocationSearchResult? _geocoded;
  double? latitude;
  double? longitude;

  void autofill(LocationSearchResult result) {
    final languageCode = Localizations.localeOf(context).languageCode;
    _geocoded = result;
    streetController.text = result.labelStreet(languageCode);
    cityController.text = result.labelCity(languageCode);
    countryController.text = result.labelCountry(languageCode);
    latitude = result.latitude;
    longitude = result.longitude;
    setState(() {});
  }

  LocalizedNames _namesFor(
    LocalizedNames stored,
    String typed,
    String languageCode,
  ) {
    if (stored.pickPreferRu(languageCode) == typed.trim()) {
      return stored;
    }
    return LocalizedNames.fill(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        InputField(
          label: l10n.houseBuilding,
          controller: commentController,
          hint: l10n.myHouseHint,
        ),
        InputField(
          label: l10n.street,
          controller: streetController,
          hint: l10n.streetHint,
        ),
        InputField(
          label: l10n.city,
          controller: cityController,
          hint: l10n.cityHint,
        ),

        const SizedBox(height: 24),

        PrimaryButton(
          label: l10n.saveLocation,
          onPressed: () async {
            final languageCode = Localizations.localeOf(context).languageCode;
            final geocoded = _geocoded;
            final location = LocationModel(
              id: '',
              service: "EQUIPMENT",
              street: streetController.text,
              streetNames: geocoded == null
                  ? LocalizedNames.fill(streetController.text)
                  : _namesFor(
                      geocoded.streetNames,
                      streetController.text,
                      languageCode,
                    ),
              houseNumber: geocoded?.houseNumber,
              city: cityController.text,
              cityNames: geocoded == null
                  ? LocalizedNames.fill(cityController.text)
                  : _namesFor(
                      geocoded.cityNames,
                      cityController.text,
                      languageCode,
                    ),
              country: countryController.text,
              countryNames: geocoded == null
                  ? LocalizedNames.fill(countryController.text)
                  : _namesFor(
                      geocoded.countryNames,
                      countryController.text,
                      languageCode,
                    ),
              region: geocoded?.region,
              regionNames: geocoded?.regionNames ?? const LocalizedNames(),
              comment: commentController.text,
              instructions: null,
              latitude: latitude ?? 0,
              longitude: longitude ?? 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            final res = await ref
                .read(locationProvider.notifier)
                .createLocation(location, "owner_address");

            if (res && context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
