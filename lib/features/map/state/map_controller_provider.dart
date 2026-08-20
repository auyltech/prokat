import 'dart:async';
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
  int _attachGeneration = 0;
  int _markerSyncGeneration = 0;

  bool _isCurrent(int attachGeneration) =>
      attachGeneration == _attachGeneration && _map != null;

  bool _isMarkerSyncCurrent(int attachGeneration, int syncGeneration) =>
      _isCurrent(attachGeneration) &&
      syncGeneration == _markerSyncGeneration &&
      _styleReady;

  bool _isDisposedChannel(Object error) {
    return error is PlatformException && error.code == 'channel-error';
  }

  void _clearAttachedMap() {
    _attachGeneration++;
    _markerSyncGeneration++;
    _styleReady = false;
    _annotationManager = null;
    _map = null;
  }

  void attach(
    MapboxMap map, {
    List<Equipment>? initialItems,
    Function(Equipment)? onTap,
  }) {
    _attachGeneration++;
    _markerSyncGeneration++;
    _annotationManager = null;
    _styleReady = false;
    _map = map;
    if (initialItems != null) _equipments = initialItems;
  }

  /// Drops Dart references to a native map that [MapWidget] already disposed.
  /// Pass [map] so an older view cannot detach a newer one.
  void detach([MapboxMap? map]) {
    if (map != null && _map != null && !identical(_map, map)) return;
    _clearAttachedMap();
  }

  Future<void> syncEquipmentMarkers(List<Equipment> items) async {
    _equipments = items;
    if (_map == null || !_styleReady) return;
    final attachGeneration = _attachGeneration;
    final syncGeneration = ++_markerSyncGeneration;
    await _addEquipmentMarkers(items, attachGeneration, syncGeneration);
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
    final attachGeneration = _attachGeneration;
    if (map == null) return;
    if (!await _hasLocationPermission()) return;
    if (!_isCurrent(attachGeneration)) return;

    try {
      await map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
        ),
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return;
    }
  }

  Future<void> moveToUserLocation(double lng, double lat) async {
    final map = _map;
    if (map == null) return;
    try {
      await map.flyTo(
        CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 14),
        MapAnimationOptions(duration: 800),
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
    }
  }

  Future<void> moveToCurrentLocation() async {
    final map = _map;
    final attachGeneration = _attachGeneration;
    if (map == null) return;
    if (!await _hasLocationPermission()) return;
    if (!_isCurrent(attachGeneration)) return;

    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled || !_isCurrent(attachGeneration)) return;

      const locationSettings = geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      );

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (!_isCurrent(attachGeneration)) return;

      await map.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 14,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return;
    }
  }

  Future<void> onStyleLoaded(StyleLoadedEventData data) async {
    final map = _map;
    final attachGeneration = _attachGeneration;
    if (map == null) return;

    try {
      _markerSyncGeneration++;
      final manager = await map.annotations.createPointAnnotationManager();
      if (!_isCurrent(attachGeneration)) return;

      _annotationManager = manager;
      _annotationManager!.tapEvents(onTap: _onAnnotationTapped);
      _styleReady = true;

      final items =
          _ref.read(clientEquipmentProvider).value?.items ?? _equipments;
      await syncEquipmentMarkers(items);
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return;
    }
  }

  Future<void> _loadMarkerIcon(int attachGeneration) async {
    final map = _map;
    if (map == null) return;

    try {
      if (await map.style.hasStyleImage(_equipmentMarkerImageId)) return;
      if (!_isCurrent(attachGeneration)) return;

      // Android BitmapFactory requires encoded PNG/JPEG bytes.
      final ByteData bytes = await rootBundle.load(_equipmentMarkerAsset);
      final png = bytes.buffer.asUint8List(
        bytes.offsetInBytes,
        bytes.lengthInBytes,
      );
      final ui.Codec codec = await ui.instantiateImageCodec(png);
      final ui.FrameInfo frame = await codec.getNextFrame();
      if (!_isCurrent(attachGeneration)) return;

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
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return;
    }
  }

  /// Load equipment pins on the map
  Future<void> _addEquipmentMarkers(
    List<Equipment> equipments,
    int attachGeneration,
    int syncGeneration,
  ) async {
    if (!_isMarkerSyncCurrent(attachGeneration, syncGeneration)) return;

    try {
      var manager = _annotationManager;
      if (manager == null) {
        final map = _map;
        if (map == null) return;
        manager = await map.annotations.createPointAnnotationManager();
        if (!_isMarkerSyncCurrent(attachGeneration, syncGeneration)) return;
        _annotationManager = manager;
      }

      await manager.deleteAll();
      if (!_isMarkerSyncCurrent(attachGeneration, syncGeneration)) return;

      await _loadMarkerIcon(attachGeneration);
      if (!_isMarkerSyncCurrent(attachGeneration, syncGeneration)) return;

      final camera = await _map?.getCameraState();
      if (camera == null ||
          !_isMarkerSyncCurrent(attachGeneration, syncGeneration)) {
        return;
      }
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
        await manager.createMulti(optionsList);
      }
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return;
    }
  }

  void _onAnnotationTapped(PointAnnotation annotation) async {
    if (_map == null) return;
    final id = annotation.customData?['id'];
    if (id == null) return;

    try {
      final equipment = _equipments.firstWhere((e) => e.id == id);
      _ref.read(equipmentMapProvider.notifier).selectEquipment(equipment);
    } catch (e) {
      return;
    }
  }

  Future<CameraState?> getCameraState() async {
    final map = _map;
    if (map == null) return null;
    try {
      return await map.getCameraState();
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return null;
    }
  }

  Future<void> flyTo(
    double longitude,
    double latitude, {
    double zoom = 14,
  }) async {
    final map = _map;
    if (map == null) return;
    try {
      await map.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: zoom,
        ),
        MapAnimationOptions(duration: 1000),
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
    }
  }

  Future<void> zoomIn() async {
    final map = _map;
    if (map == null) return;
    try {
      final camera = await map.getCameraState();
      if (_map == null) return;
      await map.flyTo(
        CameraOptions(zoom: camera.zoom + 1),
        MapAnimationOptions(duration: 300),
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
    }
  }

  Future<void> zoomOut() async {
    final map = _map;
    if (map == null) return;
    try {
      final camera = await map.getCameraState();
      if (_map == null) return;
      await map.flyTo(
        CameraOptions(zoom: camera.zoom - 1),
        MapAnimationOptions(duration: 300),
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
    }
  }

  void dispose() {
    _clearAttachedMap();
  }
}

final mapControllerProvider = Provider<MapController>((ref) {
  final controller = MapController(ref);

  ref.listen(clientEquipmentProvider, (previous, next) {
    unawaited(controller.syncEquipmentMarkers(next.value?.items ?? []));
  });

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
