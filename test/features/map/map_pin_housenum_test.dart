import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/map/services/map_pin_housenum.dart';

Map<String?, Object?> _feature({
  required String house,
  required double lng,
  required double lat,
}) {
  return {
    'type': 'Feature',
    'properties': {'house_num': house},
    'geometry': {
      'type': 'Point',
      'coordinates': [lng, lat],
    },
  };
}

void main() {
  final origin = Point(coordinates: Position(51.922724, 47.097814));

  test('houseNumberFromFeature reads house_num', () {
    expect(houseNumberFromFeature(_feature(house: '57', lng: 0, lat: 0)), '57');
  });

  test('pickNearestHouseNumber prefers closer geometry', () {
    final picked = pickNearestHouseNumber([
      _feature(house: '52', lng: 51.922981, lat: 47.097438),
      _feature(house: '57', lng: 51.92273, lat: 47.09782),
    ], origin);
    expect(picked, '57');
  });

  test('pickNearestHouseNumber respects maxDistanceSq', () {
    final picked = pickNearestHouseNumber(
      [
        _feature(house: '52', lng: 51.922981, lat: 47.097438),
        _feature(house: '57', lng: 51.923892, lat: 47.097702),
      ],
      origin,
      maxDistanceSq: housenumMaxDistanceSq,
    );
    expect(picked, '52');
  });

  test('pickNearestHouseNumber falls back when geometry missing', () {
    final picked = pickNearestHouseNumber([
      {
        'type': 'Feature',
        'properties': {'house_num': '57'},
        'geometry': null,
      },
    ], origin);
    expect(picked, '57');
  });
}
