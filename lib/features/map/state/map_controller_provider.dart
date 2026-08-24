import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_map_provider.dart';
import 'package:geolocator/geolocator.dart' as geo;

const _equipmentMarkerImageId = 'equipment-icon';
const _equipmentMarkerAsset = 'assets/icons/map_marker.png';

class MapController {
  MapController(this._ref);

  final Ref _ref;
  MapboxMap? _map;
  PointAnnotationManager? _annotationManager;
  bool markersAdded = false;
  List<Equipment> _equipments = [];
  bool _styleReady = false;

  void attach(
    MapboxMap map, {
    List<Equipment>? initialItems,
    Function(Equipment)? onTap,
  }) {
    _map = map;
    if (initialItems != null) _equipments = initialItems;
  }

  Future<void> syncEquipmentMarkers(List<Equipment> items) async {
    _equipments = items;
    if (_map == null || !_styleReady) return;
    await _addEquipmentMarkers(items);
  }

  MapboxMap get _requireMap {
    if (_map == null) {
      throw Exception("MapController not attached");
    }
    return _map!;
  }

  Future<bool> _hasLocationPermission() async {
    try {
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      return permission == geo.LocationPermission.whileInUse ||
          permission == geo.LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableUserLocation() async {
    final map = _map;
    if (map == null) return;
    if (!await _hasLocationPermission()) return;

    try {
      await map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
        ),
      );
    } catch (_) {
      return;
    }
  }

  Future<void> moveToUserLocation(double lng, double lat) async {
    await _requireMap.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 14),
      MapAnimationOptions(duration: 800),
    );
  }

  Future<void> moveToCurrentLocation() async {
    final map = _map;
    if (map == null) return;
    if (!await _hasLocationPermission()) return;

    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled || _map == null) return;

      const locationSettings = geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      );

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (_map == null) return;

      await map.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 14,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (_) {
      return;
    }
  }

  Future<void> onStyleLoaded(StyleLoadedEventData data) async {
    if (_map == null) return;

    try {
      _annotationManager = await _map!.annotations
          .createPointAnnotationManager();
      if (_map == null) return;

      _annotationManager!.tapEvents(onTap: _onAnnotationTapped);
      _styleReady = true;

      final items =
          _ref.read(clientEquipmentProvider).value?.items ?? _equipments;
      await syncEquipmentMarkers(items);
    } catch (_) {
      return;
    }
  }

  Future<void> _loadMarkerIcon() async {
    final map = _map;
    if (map == null) return;

    try {
      if (await map.style.hasStyleImage(_equipmentMarkerImageId)) return;
      if (_map == null) return;

      // Android BitmapFactory requires encoded PNG/JPEG bytes.
      final ByteData bytes = await rootBundle.load(_equipmentMarkerAsset);
      final png = bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      final ui.Codec codec = await ui.instantiateImageCodec(png);
      final ui.FrameInfo frame = await codec.getNextFrame();
      if (_map == null) return;

      await map.style.addStyleImage(
        _equipmentMarkerImageId,
        2.0,
        MbxImage(
          width: frame.image.width,
          height: frame.image.height,
          data: png,
        ),
        false,
        [],
        [],
        null,
      );
    } catch (_) {
      return;
    }
  }

  /// Load equipment pins on the map
  Future<void> _addEquipmentMarkers(List<Equipment> equipments) async {
    if (_map == null) return;

    // Ensure manager is initialized
    _annotationManager ??= await _map!.annotations
        .createPointAnnotationManager();
    await _annotationManager!.deleteAll();

    // Load/Register the icon into the map style
    await _loadMarkerIcon();

    final camera = await getCameraState();
    final zoom = camera.zoom;

    double iconSizeForZoom(double zoom) {
      if (zoom < 11) return 0.6;
      if (zoom < 13) return 0.8;
      if (zoom < 15) return 0.9;
      return 1;
    }

    final List<PointAnnotationOptions> optionsList = [];

    for (final equipment in equipments) {
      if (equipment.location == null) continue;

      final location = equipment.location;

      optionsList.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              location?.longitude ?? 0,
              location?.latitude ?? 0,
            ),
          ),
          // Provide the iconImage ID registered above
          iconImage: _equipmentMarkerImageId,
          iconSize: iconSizeForZoom(zoom),
          iconAnchor: IconAnchor.BOTTOM,
          textField: equipment.name,
          textOffset: [0, 1.2],
          customData: {'id': equipment.id},
        ),
      );
    }

    if (optionsList.isNotEmpty) {
      // Use createMulti for better performance
      await _annotationManager!.createMulti(optionsList);
    }
  }

  void _onAnnotationTapped(PointAnnotation annotation) async {
    final id = annotation.customData?['id'];
    if (id == null) return;

    try {
      // Look up the equipment from our local stored list
      final equipment = _equipments.firstWhere((e) => e.id == id);

      /// 🔥 Update global map state
      _ref.read(equipmentMapProvider.notifier).selectEquipment(equipment);

      // await _map!.flyTo(
      //   CameraOptions(center: annotation.geometry, zoom: 14),
      //   MapAnimationOptions(duration: 800),
      // );
    } catch (e) {
      return;
    }
  }

  /// Camera helpers
  Future<CameraState> getCameraState() async {
    return await _requireMap.getCameraState();
  }

  Future<void> flyTo(
    double longitude,
    double latitude, {
    double zoom = 14,
  }) async {
    await _requireMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> zoomIn() async {
    final camera = await getCameraState();

    await _requireMap.flyTo(
      CameraOptions(zoom: camera.zoom + 1),
      MapAnimationOptions(duration: 300),
    );
  }

  Future<void> zoomOut() async {
    final camera = await getCameraState();

    await _requireMap.flyTo(
      CameraOptions(zoom: camera.zoom - 1),
      MapAnimationOptions(duration: 300),
    );
  }

  void dispose() {
    _styleReady = false;
    _annotationManager = null;
    _map = null;
  }
}

final mapControllerProvider = Provider<MapController>((ref) {
  final controller = MapController(ref);

  ref.listen(clientEquipmentProvider, (previous, next) {
    controller.syncEquipmentMarkers(next.value?.items ?? []);
  });

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
