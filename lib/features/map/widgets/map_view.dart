import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/core/constants/map_constants.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/map/state/map_controller_provider.dart';
import 'package:prokat/features/map/widgets/map_controls.dart';

enum MyMapMode { browseEquipment, renterPickAddress, ownerPlaceEquipment }

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
    _mapController?.detach(_map);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MapController mapController = ref.read(mapControllerProvider);
    _mapController = mapController;

    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('prokat-map'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(
            center: Point(
              coordinates: Position(
                MapConstants.defaultLongitude,
                MapConstants.defaultLatitude,
              ),
            ),
            zoom: MapConstants.defaultZoom,
          ),
          onMapCreated: (mapboxMap) async {
            if (_closed) return;
            _map = mapboxMap;
            mapController.attach(mapboxMap, initialItems: widget.equipmentList);
            try {
              await mapController.enableUserLocation();
              if (_closed) {
                mapController.detach(mapboxMap);
                return;
              }
              await mapController.moveToCurrentLocation();
            } catch (_) {
              // Keep the map usable if location setup fails.
            }
            if (_closed) {
              mapController.detach(mapboxMap);
            }
          },
          onStyleLoadedListener: (data) async {
            if (_closed) return;
            await mapController.onStyleLoaded(data);
          },
          onCameraChangeListener: (event) {
            if (_closed) return;
            widget.onCameraIdle?.call(event);
          },
          onTapListener: (context) {
            if (_closed) return;
            widget.onMapTap?.call(context.point);
          },
        ),
        MapControls(
          onZoomIn: mapController.zoomIn,
          onZoomOut: mapController.zoomOut,
          onChangeLocation: mapController.moveToCurrentLocation,
        ),
      ],
    );
  }
}
