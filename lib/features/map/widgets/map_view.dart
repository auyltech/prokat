import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/core/constants/map_constants.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/map/state/map_controller_provider.dart';
import 'package:prokat/features/map/widgets/map_controls.dart';

enum MyMapMode { browseEquipment, renterPickAddress, ownerPlaceEquipment }

class MyMapView extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(mapControllerProvider);

    return Stack(
      children: [
        MapWidget(
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
            controller.attach(mapboxMap);

            controller.setRef(ref);

            await controller.enableUserLocation();
            await controller.moveToCurrentLocation();

            // if (mode == MyMapMode.browseEquipment) {
            //   await controller.loadEquipmentMarkers(ref);
            // }

            // if (mode == MyMapMode.browseEquipment && equipmentList != null) {
            //   await controller.renderEquipment(equipmentList!);
            // }
          },

          onStyleLoadedListener: (data) async {
            await controller.onStyleLoaded(data, ref);
          },

          onCameraChangeListener: (event) {
            if (onCameraIdle != null) {
              onCameraIdle!(event);
            }
          },

          onTapListener: (context) {
            if (onMapTap != null) {
              onMapTap!(context.point);
            }
          },
        ),

        MapControls(onZoomIn: controller.zoomIn, onZoomOut: controller.zoomOut),
      ],
    );
  }
}
