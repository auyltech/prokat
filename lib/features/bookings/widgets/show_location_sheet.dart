import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

void showLocationSheet(BuildContext context, LocationModel location) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;
  final lat = location.latitude;
  final lon = location.longitude;

  unawaited(
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final sheetTheme = Theme.of(context);
        final colorScheme = sheetTheme.colorScheme;

        return Consumer(
          builder: (context, ref, _) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      l10n.deliveryAddress,
                      style: sheetTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      formatLocationModel(ref, context, location),
                      style: sheetTheme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.map_outlined,
                        color: Colors.green,
                      ),
                      title: Text(
                        l10n.openIn2GIS,
                        style: sheetTheme.textTheme.titleMedium,
                      ),
                      onTap: () => _launchMap('2gis', lat, lon),
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(
                        l10n.openInGoogleMaps,
                        style: sheetTheme.textTheme.titleMedium,
                      ),
                      onTap: () => _launchMap('google', lat, lon),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

Future<void> _launchMap(String type, double lat, double lon) async {
  const String googleWeb = 'https://google.com';
  const String dgisWeb = 'https://2gis.kz';
  final String dgisApp = 'dgis://2gis.ru/routeSearch/rsType/car/to/$lon,$lat';

  if (type == '2gis') {
    final uriApp = Uri.parse(dgisApp);
    final uriWeb = Uri.parse(dgisWeb);

    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp);
    } else {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
    }
  } else {
    await launchUrl(Uri.parse(googleWeb), mode: LaunchMode.externalApplication);
  }
}
