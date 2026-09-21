import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

void showLocationSheet(BuildContext context, LocationModel location) {
  final l10n = AppLocalizations.of(context)!;
  final lat = location.latitude;
  final lon = location.longitude;

  unawaited(
    AppBottomSheet.show<void>(
      context,
      title: l10n.deliveryAddress,
      contentBuilder: (context) {
        final colors = context.colors;

        return Consumer(
          builder: (context, ref, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  formatLocationModel(ref, context, location),
                  textAlign: TextAlign.center,
                  style: AppFonts.body16SemiBold(context),
                ),
                const SizedBox(height: AppDimens.s12$md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.map_outlined,
                    color: colors.icons.success,
                  ),
                  title: Text(l10n.openIn2GIS, style: AppFonts.body16(context)),
                  onTap: () => _launchMap('2gis', lat, lon),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.location_on, color: colors.text.error),
                  title: Text(
                    l10n.openInGoogleMaps,
                    style: AppFonts.body16(context),
                  ),
                  onTap: () => _launchMap('google', lat, lon),
                ),
              ],
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
