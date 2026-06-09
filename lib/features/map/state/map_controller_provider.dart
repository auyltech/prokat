import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/equipment_map_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:geolocator/geolocator.dart' as geo;

class MapController {
  MapboxMap? _map;
  PointAnnotationManager? _annotationManager;
  bool markersAdded = false;
  // CircleAnnotationManager? _circleManager;
  // bool _markersAdded = false;
  List<Equipment> _equipments = [];
  // Function(Equipment)? onEquipmentTapped;

  late WidgetRef _ref;

  void attach(
    MapboxMap map, {
    List<Equipment>? initialItems,
    Function(Equipment)? onTap,
  }) {
    _map = map;
    if (initialItems != null) _equipments = initialItems;
    // if (onTap != null) onEquipmentTapped = onTap;
  }

  void setRef(WidgetRef ref) {
    _ref = ref;

    /// Listen to equipment changes
    ref.listen(equipmentProvider, (prev, next) async {
      if (_map == null || next.renterEquipment.isEmpty) return;

      await _addEquipmentMarkers(next.renterEquipment);
    });
  }

  MapboxMap get _requireMap {
    if (_map == null) {
      throw Exception("MapController not attached");
    }
    return _map!;
  }

  Future<void> enableUserLocation() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return;
    }

    await _requireMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        showAccuracyRing: true,
      ),
    );
  }

  Future<void> moveToUserLocation(double lng, double lat) async {
    await _requireMap.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 14),
      MapAnimationOptions(duration: 800),
    );
  }

  Future<void> moveToCurrentLocation() async {
    final map = _requireMap;

    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    geo.LocationPermission permission = await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return;
    }

    const locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
    );

    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    await map.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 14,
      ),
      MapAnimationOptions(duration: 1200),
    );
  }

  Future<void> onStyleLoaded(StyleLoadedEventData data, WidgetRef ref) async {
    if (_map == null) return;

    _annotationManager = await _map!.annotations.createPointAnnotationManager();

    _annotationManager!.tapEvents(onTap: _onAnnotationTapped);

    // 🔑 Read equipment data ONCE
    final equipmentState = ref.read(equipmentProvider);

    if (equipmentState.renterEquipment.isEmpty) return;

    _equipments = equipmentState.renterEquipment;
    await _addEquipmentMarkers(equipmentState.renterEquipment);
  }

  Future<void> _loadMarkerIcon() async {
    if (_map == null) return;

    // 1. Load image from assets
    final ByteData bytes = await rootBundle.load(
      'assets/images/icons/truck_96.png',
    );
    final Uint8List list = bytes.buffer.asUint8List();

    // 2. Mapbox requires the exact width/height for the MbxImage object
    final ui.Codec codec = await ui.instantiateImageCodec(list);
    final ui.FrameInfo frame = await codec.getNextFrame();

    final mbxImage = MbxImage(
      width: frame.image.width,
      height: frame.image.height,
      data: list,
    );

    // 3. Add to style with the ID 'equipment-icon'
    await _map!.style.addStyleImage(
      'equipment-icon',
      1.0, // Scale
      mbxImage,
      false,
      [],
      [],
      null,
    );
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
          iconImage: 'equipment-icon',
          iconSize: iconSizeForZoom(zoom),
          // Add text labels
          textField: equipment.name,
          textOffset: [0, 2.0],
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
    _annotationManager = null;
    _map = null;
  }
}

final mapControllerProvider = Provider<MapController>((ref) {
  final controller = MapController();

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
