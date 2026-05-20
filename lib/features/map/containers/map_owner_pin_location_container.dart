import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/map/widgets/map_view.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapOwnerPinLocationContainer extends ConsumerStatefulWidget {
  final String equipmentId;

  const MapOwnerPinLocationContainer({super.key, required this.equipmentId});

  @override
  ConsumerState<MapOwnerPinLocationContainer> createState() =>
      _MapOwnerPinLocationContainerState();
}

class _MapOwnerPinLocationContainerState
    extends ConsumerState<MapOwnerPinLocationContainer> {
  double latitude = 0;
  double longitude = 0;

  LocationSearchResult? selectedAddress;
  bool loadingAddress = false;

  Timer? idleDebounce;

  Future<void> reverseGeocode() async {
    setState(() {
      loadingAddress = true;
      selectedAddress = null;
    });

    try {
      final result = await ref
          .read(locationApiProvider)
          .reverseGeocode(longitude, latitude);

      if (result != null) {
        setState(() {
          selectedAddress = result;
        });
      }
    } catch (e) {
      debugPrint("Geocoding failed: $e");
    } finally {
      setState(() {
        loadingAddress = false;
      });
    }
  }

  void onCameraIdle(CameraChangedEventData data) {
    idleDebounce?.cancel();

    setState(() {
      selectedAddress = null;
    });

    idleDebounce = Timer(const Duration(milliseconds: 600), () {
      latitude = data.cameraState.center.coordinates.lat.toDouble();
      longitude = data.cameraState.center.coordinates.lng.toDouble();

      reverseGeocode();
    });
  }

  Future<void> confirmLocation() async {
    if (selectedAddress == null) return;

    final notifier = ref.read(locationProvider.notifier);

    try {
      final location = LocationModel(
        service: "EQUIPMENT",
        street: selectedAddress!.street,
        city: selectedAddress!.city ?? "",
        country: selectedAddress!.country ?? "",
        latitude: latitude,
        longitude: longitude,
        equipmentId: widget.equipmentId,
      );

      final created = await notifier.createLocation(location);

      if (!mounted) return;

      if (created == true) {
        Navigator.pop(context, created);
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedCreateLocation)),
      );
    }
  }

  @override
  void dispose() {
    idleDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          MyMapView(
            mode: MyMapMode.ownerPlaceEquipment,
            onCameraIdle: onCameraIdle,
          ),

          /// CENTER PIN
          const Center(
            child: IgnorePointer(
              child: Icon(Icons.location_pin, size: 50, color: Colors.red),
            ),
          ),

          /// ADDRESS PANEL
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black12),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loadingAddress)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    else if (selectedAddress != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAddress!.street,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [selectedAddress!.city, selectedAddress!.country]
                                .where((e) => e != null && e.isNotEmpty)
                                .join(", "),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedAddress == null
                            ? null
                            : confirmLocation,
                        child: Text(l10n.confirmLocation),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
