import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class LocationTile extends ConsumerWidget {
  final LocationModel location;
  final VoidCallback onTap;

  const LocationTile({super.key, required this.location, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
          formatLocationModel(ref, context, location),
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
