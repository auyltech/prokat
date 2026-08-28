import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AddressListTile extends ConsumerWidget {
  final LocationModel location;

  const AddressListTile({super.key, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(
        formatStreetCity(
          l10n: AppLocalizations.of(context)!,
          street: location.street,
          city: catalogCityLabelOf(ref, context, location.city),
        ),
      ),
      subtitle: Text(location.country),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // later: edit screen
      },
    );
  }
}
