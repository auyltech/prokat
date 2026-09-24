import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../../locations/models/location_search_result.dart';

class MapAddressPreview extends ConsumerWidget {
  final bool loading;
  final LocationSearchResult? address;
  final VoidCallback? onConfirm;

  const MapAddressPreview({
    super.key,
    required this.loading,
    required this.address,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                )
              else if (address != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address!.streetLine(languageCode),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      [
                        locationCityLabel(
                          ref,
                          context,
                          city: address!.city,
                          names: address!.cityNames,
                        ),
                        address!.labelCountry(languageCode),
                      ].where((e) => e.isNotEmpty).join(", "),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              AppElevatedButton(
                title: l10n.confirmLocation,
                onTap: address == null ? null : onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
