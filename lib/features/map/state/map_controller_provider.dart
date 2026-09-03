import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_map_provider.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/map/services/map_pin_housenum.dart';
import 'package:prokat/features/map/services/map_pin_streets.dart';
import 'package:geolocator/geolocator.dart' as geo;

const _equipmentMarkerImageId = 'equipment-icon';
const _equipmentMarkerAsset = 'assets/icons/map_marker.png';

class MapPinTarget {
  const MapPinTarget({
    required this.point,
    this.houseNumber,
    this.nearbyStreets = const [],
  });

  final Point point;
  final String? houseNumber;
  final List<LocalizedNames> nearbyStreets;
}

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
  GlobalKey? _mapViewKey;
  GlobalKey? _pinIconKey;

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

  void bindOverlayKeys({GlobalKey? mapViewKey, GlobalKey? pinIconKey}) {
    _mapViewKey = mapViewKey;
    _pinIconKey = pinIconKey;
  }

  ScreenCoordinate? _pinTipPixel() {
    final mapBox =
        _mapViewKey?.currentContext?.findRenderObject() as RenderBox?;
    final pinBox =
        _pinIconKey?.currentContext?.findRenderObject() as RenderBox?;
    if (mapBox == null ||
        pinBox == null ||
        !mapBox.hasSize ||
        !pinBox.hasSize) {
      return null;
    }

    final tipGlobal = pinBox.localToGlobal(
      Offset(pinBox.size.width / 2, pinBox.size.height),
    );
    final tipInMap = mapBox.globalToLocal(tipGlobal);
    return ScreenCoordinate(x: tipInMap.dx, y: tipInMap.dy);
  }

  /// Geographic point under the overlay pin tip, not the camera/icon center.
  Future<Point?> coordinateAtPinTip() async {
    final map = _map;
    if (map == null) return null;

    try {
      final pixel = _pinTipPixel();
      if (pixel != null) {
        return await map.coordinateForPixel(pixel);
      }

      final camera = await map.getCameraState();
      return camera.center;
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return null;
    }
  }

  /// House number from Streets tiles at the pin tip.
  ///
  /// Prefers the painted `housenum-label` (matches what the user sees). If the
  /// label is decluttered but tile data is loaded (zoom ≥ 16), falls back to
  /// the nearest `housenum_label` in the composite source. Miss → null so
  /// reverse geocode keeps its own house number.
  Future<String?> houseNumberAtPinTip([Point? at]) async {
    final map = _map;
    if (map == null) return null;

    try {
      final pixel = _pinTipPixel();
      final origin = at ??
          (pixel != null
              ? await map.coordinateForPixel(pixel)
              : (await map.getCameraState()).center);

      if (pixel != null) {
        final rendered = await map.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenBox(
            ScreenBox(
              min: ScreenCoordinate(
                x: pixel.x - housenumQueryPadPx,
                y: pixel.y - housenumQueryPadPx,
              ),
              max: ScreenCoordinate(
                x: pixel.x + housenumQueryPadPx,
                y: pixel.y + housenumQueryPadPx,
              ),
            ),
          ),
          RenderedQueryOptions(layerIds: [housenumLabelLayerId]),
        );
        final fromRendered = pickNearestHouseNumber(
          [
            for (final hit in rendered)
              if (hit?.queriedFeature.feature != null)
                hit!.queriedFeature.feature,
          ],
          origin,
        );
        if (fromRendered != null) return fromRendered;
      }

      final sourced = await map.querySourceFeatures(
        housenumCompositeSourceId,
        SourceQueryOptions(
          sourceLayerIds: [housenumSourceLayerId],
          filter: '["has","house_num"]',
        ),
      );
      return pickNearestHouseNumber(
        [
          for (final hit in sourced)
            if (hit?.queriedFeature.feature != null)
              hit!.queriedFeature.feature,
        ],
        origin,
        maxDistanceSq: housenumMaxDistanceSq,
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return null;
    }
  }

  Future<List<LocalizedNames>> streetsAtPinTip(Point origin) async {
    final map = _map;
    if (map == null) return const [];

    try {
      final features = <Map<String?, Object?>>[];

      final sourced = await map.querySourceFeatures(
        roadCompositeSourceId,
        SourceQueryOptions(
          sourceLayerIds: [roadSourceLayerId],
          filter: '["has","name"]',
        ),
      );
      for (final hit in sourced) {
        final feature = hit?.queriedFeature.feature;
        if (feature != null) features.add(feature);
      }

      final pixel = _pinTipPixel();
      if (pixel != null) {
        final pad = await _metersToPixels(map, origin, roadQueryRadiusMeters);
        final rendered = await map.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenBox(
            ScreenBox(
              min: ScreenCoordinate(x: pixel.x - pad, y: pixel.y - pad),
              max: ScreenCoordinate(x: pixel.x + pad, y: pixel.y + pad),
            ),
          ),
          RenderedQueryOptions(layerIds: [roadLabelLayerId]),
        );
        for (final hit in rendered) {
          final feature = hit?.queriedFeature.feature;
          if (feature != null) features.add(feature);
        }
      }

      return pickNearbyStreets(features, origin);
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
      return const [];
    }
  }

  Future<double> _metersToPixels(
    MapboxMap map,
    Point origin,
    double meters,
  ) async {
    const metersPerDegLat = 111320.0;
    final north = Point(
      coordinates: Position(
        origin.coordinates.lng,
        origin.coordinates.lat + meters / metersPerDegLat,
      ),
    );
    final a = await map.pixelForCoordinate(origin);
    final b = await map.pixelForCoordinate(north);
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy).clamp(36.0, 220.0);
  }

  Future<MapPinTarget?> pinTarget() async {
    final point = await coordinateAtPinTip();
    if (point == null) return null;
    final houseNumber = await houseNumberAtPinTip(point);
    final nearbyStreets = await streetsAtPinTip(point);
    return MapPinTarget(
      point: point,
      houseNumber: houseNumber,
      nearbyStreets: nearbyStreets,
    );
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
    } on geo.PermissionDefinitionsNotFoundException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableUserLocation() async {
    final map = _map;
    final attachGeneration = _attachGeneration;
    if (map == null) return;

    try {
      if (!await _hasLocationPermission()) return;
      if (!_isCurrent(attachGeneration)) return;

      await map.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
        ),
      );
    } catch (error) {
      if (_isDisposedChannel(error)) _clearAttachedMap();
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

    try {
      if (!await _hasLocationPermission()) return;
      if (!_isCurrent(attachGeneration)) return;

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
