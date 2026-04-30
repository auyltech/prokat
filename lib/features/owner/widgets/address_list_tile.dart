import 'package:flutter/material.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class AddressListTile extends StatelessWidget {
  final LocationModel location;

  const AddressListTile({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text("${location.street}, ${location.city}"),
      subtitle: Text(location.country),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // later: edit screen
      },
    );
  }
}
