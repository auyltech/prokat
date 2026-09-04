import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/map/services/map_pin_streets.dart';
import 'package:prokat/features/map/state/map_controller_provider.dart';
import 'package:prokat/features/map/widgets/map_pin_address_panel.dart';
import 'package:prokat/features/map/widgets/map_view.dart';
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
  List<LocalizedNames> _streetOptions = [];
  final _houseController = TextEditingController();
  final _houseFocusNode = FocusNode();

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
    _houseController.dispose();
    _houseFocusNode.dispose();
    super.dispose();
  }

  Future<void> reverseGeocode({
    String? mapHouseNumber,
    List<LocalizedNames> tileStreets = const [],
  }) async {
    if (_closed) return;

    setState(() {
      loadingAddress = true;
      selectedAddress = null;
      _streetOptions = [];
    });
    _houseController.clear();

    try {
      if (_closed) return;
      final api = ref.read(locationApiProvider);
      final result = await api.reverseGeocode(longitude, latitude);

      if (_closed) return;

      if (result != null) {
        final choice = choosePinStreets(
          reverseStreet: result.streetNames,
          tileStreets: tileStreets,
          reverseFallback: result.street,
        );
        final house = mapHouseNumber?.trim();
        final resolvedHouse = (house != null && house.isNotEmpty)
            ? house
            : result.houseNumber;
        _streetOptions = choice.options;
        _houseController.text = resolvedHouse ?? '';
        setState(() {
          selectedAddress = result
              .withStreetNames(choice.selected)
              .withHouseNumber(resolvedHouse);
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

  bool get _keyboardOpen => MediaQuery.viewInsetsOf(context).bottom > 0;

  void onCameraIdle(CameraChangedEventData _) {
    idleDebounce?.cancel();
    if (_closed) return;
    if (_houseFocusNode.hasFocus || _keyboardOpen) return;

    if (selectedAddress != null) {
      setState(() {
        selectedAddress = null;
      });
    }

    final controller = ref.read(mapControllerProvider);

    idleDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (_closed) return;
      final target = await controller.pinTarget();
      if (_closed || target == null) return;
      latitude = target.point.coordinates.lat.toDouble();
      longitude = target.point.coordinates.lng.toDouble();

      unawaited(
        reverseGeocode(
          mapHouseNumber: target.houseNumber,
          tileStreets: target.nearbyStreets,
        ),
      );
    });
  }

  Future<void> createAddress() async {
    try {
      final location = LocationModel.fromSearchResult(
        selectedAddress!.withHouseNumber(_houseController.text),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.failedSaveAddress)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          /// MAP
          Positioned.fill(
            child: MyMapView(
              mode: MyMapMode.renterPickAddress,
              onCameraIdle: onCameraIdle,
              onMapTap: (_) => _houseFocusNode.unfocus(),
            ),
          ),

          MapPinAddressPanel(
            loading: loadingAddress,
            address: selectedAddress,
            streetOptions: _streetOptions,
            houseController: _houseController,
            houseFocusNode: _houseFocusNode,
            onStreetSelected: (names) {
              final current = selectedAddress;
              if (current == null) return;
              setState(() {
                selectedAddress = current.withStreetNames(names);
              });
            },
            confirmButton: SizedBox(
              width: double.infinity,
              child: ActionButton(
                onPressed: selectedAddress == null ? null : createAddress,
                label: l10n.saveAddress,
                isLoading: ref
                    .watch(locationProvider)
                    .isActionActive("location:create"),
                isEnabled: !ref
                    .watch(locationProvider)
                    .isActionActive("location:create"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
