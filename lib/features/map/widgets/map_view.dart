import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/core/constants/map_constants.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/map/services/map_language.dart';
import 'package:prokat/features/map/state/map_controller_provider.dart';
import 'package:prokat/features/map/widgets/map_controls.dart';
import 'package:prokat/features/map/widgets/center_pin.dart';

enum MyMapMode { browseEquipment, renterPickAddress, ownerPlaceEquipment }

const _mapTapInteractionId = 'prokat-map-tap';

/// Stable instance: Mapbox reapplies [MapWidget.viewport] whenever the object
/// identity changes, which snaps the camera back to this position.
final _defaultMapViewport = CameraViewportState(
  center: Point(
    coordinates: Position(
      MapConstants.defaultLongitude,
      MapConstants.defaultLatitude,
    ),
  ),
  zoom: MapConstants.defaultZoom,
);

class MyMapView extends ConsumerStatefulWidget {
  final MyMapMode mode;
  final Function(CameraChangedEventData data)? onCameraIdle;
  final Function(Point point)? onMapTap;
  final List<Equipment>? equipmentList;

  const MyMapView({
    super.key,
    required this.mode,
    this.onCameraIdle,
    this.onMapTap,
    this.equipmentList,
  });

  @override
  ConsumerState<MyMapView> createState() => _MyMapViewState();
}

class _MyMapViewState extends ConsumerState<MyMapView> {
  MapboxMap? _map;
  MapController? _mapController;
  bool _closed = false;
  bool _languageReady = false;
  ViewportState _viewport = _defaultMapViewport;
  final GlobalKey _mapViewKey = GlobalKey();
  final GlobalKey _pinIconKey = GlobalKey();
  late String _mapLanguage;
  ProviderSubscription<Locale>? _localeSub;

  bool get _showCenterPin =>
      widget.mode == MyMapMode.renterPickAddress ||
      widget.mode == MyMapMode.ownerPlaceEquipment;

  @override
  void initState() {
    super.initState();
    _mapLanguage = ref.read(localeProvider).languageCode;
    _localeSub = ref.listenManual(localeProvider, (previous, next) {
      if (previous?.languageCode == next.languageCode) return;
      _mapLanguage = next.languageCode;
      unawaited(_onAppLocaleChanged());
    });
    unawaited(_prepareMapLanguage());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mapController = ref.read(mapControllerProvider);
  }

  @override
  void activate() {
    super.activate();
    _closed = false;
  }

  @override
  void deactivate() {
    _closed = true;
    super.deactivate();
  }

  @override
  void dispose() {
    _localeSub?.close();
    _mapController?.detach(_map);
    super.dispose();
  }

  Future<void> _prepareMapLanguage() async {
    try {
      await ref.read(localeProvider.notifier).hydrated;
    } catch (_) {}
    if (!mounted || _closed) return;
    _mapLanguage = ref.read(localeProvider).languageCode;
    await applyMapboxLanguagePreference(_mapLanguage);
    if (!mounted || _closed) return;
    setState(() => _languageReady = true);
  }

  Future<void> _onAppLocaleChanged() async {
    await applyMapboxLanguagePreference(_mapLanguage);
    final map = _map;
    if (_closed || map == null) return;
    await localizeMapboxLabels(map, _mapLanguage);
  }

  Future<void> _localizeLoadedStyle(MapboxMap map) async {
    if (_closed) return;
    await localizeMapboxLabels(map, _mapLanguage);
  }

  /// Lets the user pan/zoom without Mapbox re-applying the initial camera.
  void _giveCameraToUser() {
    if (_closed || !mounted || _viewport is IdleViewportState) return;
    setState(() => _viewport = const IdleViewportState());
  }

  @override
  Widget build(BuildContext context) {
    final MapController mapController = ref.read(mapControllerProvider);
    _mapController = mapController;
    mapController.bindOverlayKeys(
      mapViewKey: _mapViewKey,
      pinIconKey: _showCenterPin ? _pinIconKey : null,
    );

    return Stack(
      children: [
        if (_languageReady)
          MapWidget(
            key: _mapViewKey,
            styleUri: MapboxStyles.MAPBOX_STREETS,
            viewport: _viewport,
            onMapCreated: (mapboxMap) async {
              if (_closed) return;
              _map = mapboxMap;
              mapboxMap.addInteraction(
                TapInteraction.onMap((context) {
                  if (_closed) return;
                  widget.onMapTap?.call(context.point);
                }),
                interactionID: _mapTapInteractionId,
              );
              mapController.attach(mapboxMap, initialItems: widget.equipmentList);
              try {
                if (await mapboxMap.style.isStyleLoaded()) {
                  await _localizeLoadedStyle(mapboxMap);
                }
              } catch (_) {}
              try {
                await mapController.enableUserLocation();
                if (_closed) {
                  mapboxMap.removeInteraction(_mapTapInteractionId);
                  mapController.detach(mapboxMap);
                  return;
                }
                await mapController.moveToCurrentLocation();
              } catch (_) {
                // Keep the map usable if location setup fails.
              }
              if (_closed) {
                mapboxMap.removeInteraction(_mapTapInteractionId);
                mapController.detach(mapboxMap);
                return;
              }
              _giveCameraToUser();
            },
            onStyleLoadedListener: (data) async {
              if (_closed) return;
              final map = _map;
              if (map != null) await _localizeLoadedStyle(map);
              if (_closed) return;
              await mapController.onStyleLoaded(data);
            },
            onCameraChangeListener: (event) {
              if (_closed) return;
              widget.onCameraIdle?.call(event);
            },
          ),
        if (_showCenterPin) CenterPin(iconKey: _pinIconKey),
        MapControls(
          onZoomIn: mapController.zoomIn,
          onZoomOut: mapController.zoomOut,
          onChangeLocation: mapController.moveToCurrentLocation,
        ),
      ],
    );
  }
}
