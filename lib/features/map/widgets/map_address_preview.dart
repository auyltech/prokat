import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';
import '../../locations/models/location_search_result.dart';

class MapAddressPreview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                      address!.street,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      [
                        address!.city,
                        address!.country,
                      ].where((e) => e != null && e.isNotEmpty).join(", "),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: address == null ? null : onConfirm,
                  child: Text(l10n.confirmLocation),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
