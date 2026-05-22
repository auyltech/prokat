import 'package:flutter/material.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

void showLocationSheet(BuildContext context, LocationModel location) {
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;
  final lat = location.latitude;
  final lon = location.longitude;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deliveryAddress, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            "${location.street}, ${location.city}",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(Icons.map_outlined, color: Colors.green),
            title: Text(l10n.openIn2GIS),
            onTap: () => _launchMap('2gis', lat, lon),
          ),

          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.red),
            title: Text(l10n.openInGoogleMaps),
            onTap: () => _launchMap('google', lat, lon),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Future<void> _launchMap(String type, double lat, double lon) async {
  final String googleWeb = 'https://google.com';
  final String dgisWeb = 'https://2gis.kz';
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
