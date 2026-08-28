import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/features/locations/location_label.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/map/widgets/map_view.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapClientPinAddressContainer extends ConsumerStatefulWidget {
  final String from;

  const MapClientPinAddressContainer({super.key, required this.from});

  @override
  ConsumerState<MapClientPinAddressContainer> createState() =>
      _MapClientPinAddressContainerState();
}

class _MapClientPinAddressContainerState
    extends ConsumerState<MapClientPinAddressContainer> {
  double latitude = 0;
  double longitude = 0;

  LocationSearchResult? selectedAddress;
  bool loadingAddress = false;

  Timer? idleDebounce;
  bool _closed = false;

  @override
  void activate() {
    super.activate();
    _closed = false;
  }

  @override
  void deactivate() {
    _closed = true;
    idleDebounce?.cancel();
    super.deactivate();
  }

  @override
  void dispose() {
    idleDebounce?.cancel();
    super.dispose();
  }

  Future<void> reverseGeocode() async {
    if (_closed) return;

    setState(() {
      loadingAddress = true;
      selectedAddress = null;
    });

    try {
      if (_closed) return;
      final api = ref.read(locationApiProvider);
      final result = await api.reverseGeocode(longitude, latitude);

      if (_closed) return;

      if (result != null) {
        setState(() {
          selectedAddress = result;
        });
      }
    } catch (e) {
      if (_closed) return;
      debugPrint("Geocoding failed: $e");
    } finally {
      if (!_closed) {
        setState(() {
          loadingAddress = false;
        });
      }
    }
  }

  void onCameraIdle(CameraChangedEventData data) {
    idleDebounce?.cancel();
    if (_closed) return;

    setState(() {
      selectedAddress = null;
    });

    idleDebounce = Timer(const Duration(milliseconds: 600), () {
      if (_closed) return;
      latitude = data.cameraState.center.coordinates.lat.toDouble();
      longitude = data.cameraState.center.coordinates.lng.toDouble();

      reverseGeocode();
    });
  }

  Future<void> createAddress() async {
    try {
      final location = LocationModel.fromSearchResult(
        selectedAddress!,
        service: "ADDRESS",
        latitude: latitude,
        longitude: longitude,
      );

      final created = await ref
          .read(locationProvider.notifier)
          .createLocation(location, widget.from);

      if (created && mounted && context.canPop()) {
        Navigator.pop(context, location); // return to booking screen
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.failedSaveAddress)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          MyMapView(
            mode: MyMapMode.renterPickAddress,
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
                            selectedAddress!.streetLine(
                              Localizations.localeOf(context).languageCode,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatCityCountry(
                              l10n: l10n,
                              city: locationCityLabel(
                                ref,
                                context,
                                city: selectedAddress!.city,
                                names: selectedAddress!.cityNames,
                              ),
                              country: selectedAddress!.labelCountry(
                                Localizations.localeOf(context).languageCode,
                              ),
                            ),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ActionButton(
                        onPressed: selectedAddress == null
                            ? null
                            : createAddress,
                        label: l10n.saveAddress,
                        isLoading: ref
                            .watch(locationProvider)
                            .isActionActive("location:create"),
                        isEnabled: !ref
                            .watch(locationProvider)
                            .isActionActive("location:create"),
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
