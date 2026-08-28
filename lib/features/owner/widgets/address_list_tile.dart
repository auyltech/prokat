import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class AddressListTile extends ConsumerWidget {
  final LocationModel location;

  const AddressListTile({super.key, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(formatLocationModel(ref, context, location)),
      subtitle: Text(
        location.labelCountry(Localizations.localeOf(context).languageCode),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // later: edit screen
      },
    );
  }
}
