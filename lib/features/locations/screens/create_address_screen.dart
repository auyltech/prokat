import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import '../../owner/widgets/address_form.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateAddressScreen extends ConsumerStatefulWidget {
  final String service;
  final String from;
  final String? redirectUrl;
  final String? equipmentId;

  const CreateAddressScreen({
    super.key,
    required this.service,
    this.equipmentId,
    this.redirectUrl,
    this.from = "",
  });

  @override
  ConsumerState<CreateAddressScreen> createState() =>
      _CreateAddressScreenState();
}

class _CreateAddressScreenState extends ConsumerState<CreateAddressScreen> {
  final formKey = GlobalKey<AddressFormState>();

  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final countryController = TextEditingController();
  final commentController = TextEditingController();

  double? latitude;
  double? longitude;

  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

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

  Future<void> _onPressed() async {
    final location = LocationModel(
      id: '',
      service: widget.service == "equipment" ? "EQUIPMENT" : "ADDRESS",
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
        .createLocation(location, widget.from);

    if (!mounted) return;

    if (res) {
      final url = widget.service == "equipment"
          ? "${AppRoutes.ownerEquiment}/${widget.equipmentId}"
          : "${AppRoutes.equipment}/${widget.equipmentId}";

      context.push(url);
      AppSnackBar.show(message: _l10n.addressCreated, isSuccess: true);
    } else {
      AppSnackBar.show(message: _l10n.failedCreateAddress, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                      ? l10n.addLocation
                      : l10n.addAddress,
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                InputField(
                  label: l10n.houseBuilding,
                  controller: commentController,
                  hint: l10n.myHouseHint,
                ),
                const SizedBox(height: 8),
                InputField(
                  label: l10n.street,
                  controller: streetController,
                  hint: l10n.streetHint,
                ),
                const SizedBox(height: 8),
                InputField(
                  label: l10n.city,
                  controller: cityController,
                  hint: l10n.cityHint,
                ),

                const SizedBox(height: 24),

                PrimaryButton(label: l10n.saveLocation, onPressed: _onPressed),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
