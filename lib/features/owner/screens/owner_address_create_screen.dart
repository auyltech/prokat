import 'package:flutter/material.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import '../widgets/address_form.dart';
import '../widgets/address_search_box.dart';

class OwnerAddressCreateScreen extends StatefulWidget {
  const OwnerAddressCreateScreen({super.key});

  @override
  State<OwnerAddressCreateScreen> createState() =>
      _OwnerAddressCreateScreenState();
}

class _OwnerAddressCreateScreenState extends State<OwnerAddressCreateScreen> {
  final formKey = GlobalKey<AddressFormState>();

  void onAddressSelected(LocationSearchResult result) {
    formKey.currentState?.autofill(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Equipment Location")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AddressSearchBox(onSelected: onAddressSelected),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(child: AddressForm(key: formKey)),
            ),
          ],
        ),
      ),
    );
  }
}
