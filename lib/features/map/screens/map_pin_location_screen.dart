import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/owner/widgets/address_search_box.dart';
import '../../locations/models/location_search_result.dart';
import '../../locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapPinLocationScreen extends ConsumerStatefulWidget {
  final String? equipmentId;

  const MapPinLocationScreen({super.key, this.equipmentId});

  @override
  ConsumerState<MapPinLocationScreen> createState() =>
      _MapPinLocationScreenState();
}

class _MapPinLocationScreenState extends ConsumerState<MapPinLocationScreen> {
  MapboxMap? mapboxMap;

  double latitude = 0;
  double longitude = 0;

  LocationSearchResult? selectedAddress;

  bool loadingAddress = false;

  Timer? idleDebounce;

  @override
  void initState() {
    super.initState();
  }

  Future<void> reverseGeocode() async {
    if (mapboxMap == null) return;

    setState(() {
      loadingAddress = true;
      selectedAddress = null; // Clear old address while loading
    });

    try {
      final result = await ref
          .read(locationApiProvider)
          .reverseGeocode(longitude, latitude);

      // Only update if we actually got a result
      if (result != null) {
        setState(() {
          selectedAddress = result;
        });
      }
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

    idleDebounce = Timer(const Duration(milliseconds: 600), () async {
      final center = await mapboxMap!.getCameraState();

      latitude = center.center.coordinates.lat.toDouble();
      longitude = center.center.coordinates.lng.toDouble();

      reverseGeocode();
    });
  }

  void moveToSearch(LocationSearchResult result) async {
    if (mapboxMap == null) return;

    await mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(result.longitude, result.latitude)),
        zoom: 16,
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  Future<void> moveToCurrentLocation() async {
    if (mapboxMap == null) return;

    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return;
    }

    // 2. Use the prefix for LocationSettings
    const locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
    );

    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    await mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          // 3. Mapbox uses Position(lng, lat)
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 16,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> confirmLocation() async {
    if (selectedAddress == null) return;

    final notifier = ref.read(locationProvider.notifier);

    final equipmentId = widget.equipmentId;

    if (equipmentId == null) {
      return;
    }

    try {
      final location = LocationModel(
        service: "EQUIPMENT",
        street: selectedAddress!.street,
        city: selectedAddress!.city ?? "",
        country: selectedAddress!.country ?? "",
        latitude: latitude,
        longitude: longitude,
        equipmentId: equipmentId,
      );

      final created = await notifier.createLocation(location);

      if (created != true && !mounted) return;

      Navigator.pop(context, created);
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.failedCreateLocation)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          MapWidget(
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(51.1694, 43.2220), // example coordinates
              ),
              zoom: 10,
            ),
            onCameraChangeListener: onCameraIdle,
            onMapCreated: (controller) async {
              mapboxMap = controller;

              await mapboxMap!.location.updateSettings(
                LocationComponentSettings(enabled: true, pulsingEnabled: true),
              );

              final center = await mapboxMap!.getCameraState();

              latitude = center.center.coordinates.lat.toDouble();
              longitude = center.center.coordinates.lng.toDouble();

              // reverseGeocode(); // initial address fetch
            },
          ),

          /// CENTER PIN
          const Center(
            child: IgnorePointer(
              child: Icon(Icons.location_pin, size: 50, color: Colors.red),
            ),
          ),

          /// SEARCH BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AddressSearchBox(
                onSelected: (result) {
                  moveToSearch(result);
                },
              ),
            ),
          ),

          /// GPS BUTTON
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              heroTag: "gps",
              onPressed: moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          /// ADDRESS PREVIEW PANEL
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
