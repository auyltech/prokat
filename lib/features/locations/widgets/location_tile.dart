import 'package:flutter/material.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LocationTile extends StatelessWidget {
  final LocationModel location;
  final VoidCallback onTap;

  const LocationTile({super.key, required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceBright,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(50)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.location_on_outlined,
          color: theme.colorScheme.onSurface,
          size: 24,
        ),
        title: Text(
          formatStreetCity(
            l10n: l10n,
            street: location.street,
            city: location.city,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}
