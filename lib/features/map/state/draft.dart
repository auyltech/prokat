// Future<void> _loadLocationIcon() async {
//   final ByteData bytes = await rootBundle.load(
//     'assets/images/icons/current_location.png',
//   );

//   final Uint8List list = bytes.buffer.asUint8List();

//   final ui.Codec codec = await ui.instantiateImageCodec(list);
//   final ui.FrameInfo frame = await codec.getNextFrame();

//   final mbxImage = MbxImage(
//     width: frame.image.width,
//     height: frame.image.height,
//     data: list,
//   );

//   await _map!.style.addStyleImage(
//     'user-location-icon',
//     1.0,
//     mbxImage,
//     false,
//     [],
//     [],
//     null,
//   );
// }

// import 'package:prokat/core/constants/map_constants.dart';
// Future<void> _addUserLocationMarker(double lng, double lat) async {
//   if (_annotationManager == null) return;

//   final point = Point(coordinates: Position(lng, lat));

//   final options = PointAnnotationOptions(
//     geometry: point,
//     iconImage: "marker-15", // built-in mapbox icon
//     iconSize: 1.5,
//   );

//   await _annotationManager!.create(options);
// }

// Future<void> testRender(double lng, double lat) async {
//   if (_map == null) return;

//   // 1. Initialize Managers
//   _annotationManager ??= await _map!.annotations
//       .createPointAnnotationManager();
//   _circleManager ??= await _map!.annotations.createCircleAnnotationManager();

//   // 2. Clear any existing test data
//   await _annotationManager!.deleteAll();
//   await _circleManager!.deleteAll();

//   // 3. Create a Circle (No icon dependency)
//   // Note: Position order is [Longitude, Latitude]
//   final circle = CircleAnnotationOptions(
//     geometry: Point(coordinates: Position(lng, lat)),
//     circleRadius: 12.0,
//     circleColor: Colors.red.value, // Use .value for the int color
//     circleStrokeWidth: 2.0,
//     circleStrokeColor: Colors.white.value,
//   );

//   // 4. Create a Text Label (No icon dependency)
//   final text = PointAnnotationOptions(
//     geometry: Point(coordinates: Position(lng, lat)),
//     textField: "TEST MARKER HERE",
//     textSize: 16.0,
//     textColor: Colors.blue.value,
//     textOffset: [0, 2.0], // Push text below the circle
//   );

//   await _circleManager!.create(circle);
//   await _annotationManager!.create(text);

//   print("Test annotations created at: $lng, $lat");
// }

// Future<void> _addEquipmentMarkers(List<Equipment> equipments) async {
//   if (_annotationManager == null) return;
//   await _annotationManager!.deleteAll();

//   final List<PointAnnotationOptions> options = [];

//   for (final equipment in equipments) {
//     if (equipment.locations.isEmpty) continue;
//     final loc = equipment.locations.first;

//     options.add(
//       PointAnnotationOptions(
//         geometry: Point(
//           // FIX: Ensure Longitude is first
//           coordinates: Position(loc.longitude ?? 0, loc.latitude ?? 0),
//         ),
//         // Use a built-in Mapbox icon first to verify it works
//         iconImage: 'marker-15',
//         iconSize: 1.5,
//         customData: {'id': equipment.id},
//       ),
//     );
//   }

//   await _annotationManager!.createMulti(options);
// }

// Renders saved equipment as Red Circles (to avoid icon loading issues)
// Future<void> renderEquipment(List<Equipment> equipment) async {
//   if (_map == null) return;

//   // Ensure manager exists
//   _circleManager ??= await _map!.annotations.createCircleAnnotationManager();

//   // Clear previous markers
//   await _circleManager!.deleteAll();

//   final List<CircleAnnotationOptions> annotations = [];

//   for (var item in equipment) {
//     if (item.locations.isEmpty) continue;

//     final loc = item.locations.first;

//     // FIX: Position must be [Longitude, Latitude]
//     final lng = loc.longitude ?? 0.0;
//     final lat = loc.latitude ?? 0.0;

//     annotations.add(
//       CircleAnnotationOptions(
//         geometry: Point(coordinates: Position(lng, lat)),
//         circleRadius: 8.0,
//         circleColor: Colors.red.value,
//         circleStrokeWidth: 2.0,
//         circleStrokeColor: Colors.white.value,
//       ),
//     );
//   }

//   if (annotations.isNotEmpty) {
//     await _circleManager!.createMulti(annotations);
//     debugPrint("Rendered ${annotations.length} equipment circles.");
//   }
// }
