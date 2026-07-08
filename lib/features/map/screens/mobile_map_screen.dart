import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/map/widgets/map_controls.dart';

enum MapMode { browseEquipment, pickLocation, ownerPlaceEquipment }

class MobileMapScreen extends ConsumerStatefulWidget {
  final MapMode mode;
  final Function(Position)? onLocationPicked;
  final void Function(Equipment)? onEquipmentTapped;

  const MobileMapScreen({
    super.key,
    required this.mode,
    this.onLocationPicked,
    this.onEquipmentTapped,
  });

  @override
  ConsumerState<MobileMapScreen> createState() => _MobileMapScreenState();
}

class _MobileMapScreenState extends ConsumerState<MobileMapScreen> {
  MapboxMap? _map;
  geo.Position? _userPosition;
  CameraOptions? _initialCamera;
  PointAnnotationManager? _annotationManager;

  double _zoom = 14;

  List<Equipment> _equipments = [];
  bool _markersAdded = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  // -----------------------------
  // Location
  // -----------------------------

  Future<void> _loadLocation() async {
    // NOTE: replace with real Geolocator later
    final pos = geo.Position(
      longitude: 51.924716,
      latitude: 47.095101,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    _userPosition = pos;

    _initialCamera = CameraOptions(
      center: Point(coordinates: Position(pos.longitude, pos.latitude)),
      zoom: _zoom,
    );

    if (mounted) setState(() {});
  }

  // -----------------------------
  // Map lifecycle
  // -----------------------------

  void _onMapCreated(MapboxMap mapboxMap) {
    _map = mapboxMap;

    _map!.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  void _onCameraChanged(CameraChangedEventData data) {
    _zoom = data.cameraState.zoom;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData data) async {
    if (_map == null) return;

    await _loadMarkerIcon();

    _annotationManager = await _map!.annotations.createPointAnnotationManager();

    _annotationManager!.tapEvents(onTap: _onAnnotationTapped);

    // 🔑 Read equipment data ONCE
    final equipmentAsync = ref.read(clientEquipmentProvider);

    if (_markersAdded || equipmentAsync.value?.items.isEmpty == true) return;

    _equipments = equipmentAsync.value?.items ?? [];

    await _addEquipmentMarkers(equipmentAsync.value?.items ?? []);
    _markersAdded = true;

    _moveToUserOnce();
  }

  // -----------------------------
  // Marker icon
  // -----------------------------

  Future<void> _loadMarkerIcon() async {
    final ByteData bytes = await rootBundle.load(
      'assets/images/icons/truck_96.png',
    );
    final Uint8List list = bytes.buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(list);
    final ui.FrameInfo frame = await codec.getNextFrame();

    final mbxImage = MbxImage(
      width: frame.image.width,
      height: frame.image.height,
      data: list,
    );

    await _map!.style.addStyleImage(
      'equipment-icon',
      1.0,
      mbxImage,
      false,
      [],
      [],
      null,
    );
  }

  // -----------------------------
  // Markers
  // -----------------------------

  Future<void> _addEquipmentMarkers(List<Equipment> equipments) async {
    if (_annotationManager == null) return;

    final List<PointAnnotationOptions> options = [];

    double iconSizeForZoom(double zoom) {
      if (zoom < 11) return 0.6;
      if (zoom < 13) return 0.8;
      if (zoom < 15) return 0.9;
      return 1;
    }

    for (final equipment in equipments) {
      if (equipment.location == null) continue;

      final location = equipment.location;

      options.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              location?.longitude ?? 0,
              location?.latitude ?? 0,
            ),
          ),
          iconImage: 'equipment-icon',
          iconSize: iconSizeForZoom(_zoom),
          iconOpacity: equipment.status == EquipmentStatus.available
              ? 1.0
              : 0.5,
          customData: {'id': equipment.id},
        ),
      );
    }

    await _annotationManager!.createMulti(options);
  }

  void _onAnnotationTapped(PointAnnotation annotation) {
    final id = annotation.customData?['id'];
    if (id == null) return;

    final equipment = _equipments.firstWhere((e) => e.id == id);

    widget.onEquipmentTapped?.call(equipment);
    // _showEquipmentModal(equipment);
  }

  // -----------------------------
  // Camera helpers
  // -----------------------------

  void _moveToUserOnce() {
    if (_map == null || _userPosition == null) return;

    _map!.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(
            _userPosition!.longitude,
            _userPosition!.latitude,
          ),
        ),
        zoom: _zoom,
      ),
    );
  }

  Future<void> _animateZoom(double newZoom) async {
    if (_map == null) return;

    final state = await _map!.getCameraState();
    _zoom = newZoom;

    _map!.flyTo(
      CameraOptions(
        center: state.center,
        zoom: _zoom,
        bearing: state.bearing,
        pitch: state.pitch,
      ),
      MapAnimationOptions(duration: 300),
    );
  }

  // -----------------------------
  // UI
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    if (_initialCamera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('map'),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: _initialCamera,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onCameraChangeListener: _onCameraChanged,
          ),

          MapControls(
            onZoomIn: () => _animateZoom(_zoom + 1),
            onZoomOut: () => _animateZoom(_zoom - 1),
            onChangeLocation: () async {
              await _loadLocation();
              _moveToUserOnce();
            },
          ),
        ],
      ),
    );
  }

  // void _showEquipmentModal(Equipment equipment) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (_) => EquipmentSheet(equipment: equipment),
  //   );
  // }
}
