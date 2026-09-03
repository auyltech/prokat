import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/map/services/map_pin_streets.dart';

Map<String?, Object?> _road({
  required String name,
  String? nameRu,
  String? nameEn,
  String roadClass = 'street',
  required double lng,
  required double lat,
}) {
  return {
    'type': 'Feature',
    'properties': {
      'class': roadClass,
      'name': name,
      if (nameRu != null) 'name_ru': nameRu,
      if (nameEn != null) 'name_en': nameEn,
    },
    'geometry': {
      'type': 'LineString',
      'coordinates': [
        [lng, lat],
        [lng + 0.0002, lat],
      ],
    },
  };
}

void main() {
  final origin = Point(coordinates: Position(51.900071, 47.120066));

  test('streetNamesFromFeature uses local name as kk when it differs', () {
    final names = streetNamesFromFeature(
      _road(
        name: 'Дүйсен Сүйесінов өткелі',
        nameRu: 'проезд Дуйсена Суйесинова',
        nameEn: 'Duysen Suyesinov crossing',
        lng: 51.9,
        lat: 47.12,
      ),
    );

    expect(names?.kk, 'Дүйсен Сүйесінов өткелі');
    expect(names?.ru, 'проезд Дуйсена Суйесинова');
    expect(names?.en, 'Duysen Suyesinov crossing');
  });

  test('lone label name is ru, not copied into en or kk', () {
    final names = streetNamesFromFeature(
      _road(name: 'проезд Дуйсена Суйесинова', lng: 51.9, lat: 47.12),
    );

    expect(names?.ru, 'проезд Дуйсена Суйесинова');
    expect(names?.en, '');
    expect(names?.kk, '');
  });

  test('pickNearbyStreets keeps the three named streets and drops service', () {
    final streets = pickNearbyStreets([
      _road(
        name: 'Дүйсен Сүйесінов өткелі',
        nameRu: 'проезд Дуйсена Суйесинова',
        nameEn: 'Duysen Suyesinov crossing',
        lng: 51.90007,
        lat: 47.12007,
      ),
      _road(
        name: 'Александр Афанасьев көшесі',
        nameRu: 'улица Александра Афанасьева',
        nameEn: 'Alexander Afanasyev St',
        lng: 51.9002,
        lat: 47.1198,
      ),
      _road(
        name: 'Гарифолла Құрманғалиев көшесі',
        nameRu: 'улица Гарифолла Курмангалиева',
        nameEn: 'Garifolla Kurmangalieva St',
        lng: 51.9003,
        lat: 47.1205,
      ),
      {
        'type': 'Feature',
        'properties': {'class': 'service'},
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [51.9001, 47.1201],
          ],
        },
      },
    ], origin);

    expect(streets.map((s) => s.ru).toList(), [
      'проезд Дуйсена Суйесинова',
      'улица Александра Афанасьева',
      'улица Гарифолла Курмангалиева',
    ]);
    expect(streets.first.en, isNotEmpty);
    expect(streets.first.kk, isNotEmpty);
  });

  test('pickNearbyStreets merges a Russian label with source name_en/kk', () {
    final streets = pickNearbyStreets([
      _road(name: 'проезд Дуйсена Суйесинова', lng: 51.90007, lat: 47.12007),
      _road(
        name: 'Дүйсен Сүйесінов өткелі',
        nameRu: 'проезд Дуйсена Суйесинова',
        nameEn: 'Duysen Suyesinov crossing',
        lng: 51.90008,
        lat: 47.12008,
      ),
    ], origin);

    expect(streets, hasLength(1));
    expect(streets.single.ru, 'проезд Дуйсена Суйесинова');
    expect(streets.single.en, 'Duysen Suyesinov crossing');
    expect(streets.single.kk, 'Дүйсен Сүйесінов өткелі');
  });

  test('pickNearbyStreets does not store an English label in ru', () {
    final streets = pickNearbyStreets([
      _road(name: 'Duysen Suyesinov crossing', lng: 51.90007, lat: 47.12007),
      _road(
        name: 'Дүйсен Сүйесінов өткелі',
        nameRu: 'проезд Дуйсена Суйесинова',
        nameEn: 'Duysen Suyesinov crossing',
        lng: 51.90008,
        lat: 47.12008,
      ),
    ], origin);

    expect(streets, hasLength(1));
    expect(streets.single.ru, 'проезд Дуйсена Суйесинова');
    expect(streets.single.en, 'Duysen Suyesinov crossing');
    expect(streets.single.kk, 'Дүйсен Сүйесінов өткелі');
  });

  test('mergeStreetNames prefers a real translation over a Russian copy', () {
    const tiles = LocalizedNames(
      en: 'Duysen Suyesinov crossing',
      ru: 'проезд Дуйсена Суйесинова',
      kk: 'Дүйсен Сүйесінов өткелі',
    );
    const reverseCopy = LocalizedNames(
      en: 'проезд Дуйсена Суйесинова',
      ru: 'проезд Дуйсена Суйесинова',
      kk: 'проезд Дуйсена Суйесинова',
    );

    final merged = mergeStreetNames(reverseCopy, tiles);
    expect(merged.en, 'Duysen Suyesinov crossing');
    expect(merged.kk, 'Дүйсен Сүйесінов өткелі');
    expect(merged.ru, 'проезд Дуйсена Суйесинова');
  });

  test(
    'choosePinStreets preselects the reverse street when it is on the tile',
    () {
      const reverse = LocalizedNames(
        en: 'Alexander Afanasyev Street',
        ru: 'улица Александра Афанасьева',
        kk: 'Александр Афанасьев көшесі',
      );
      const tiles = [
        LocalizedNames(
          en: 'Duysen Suyesinov crossing',
          ru: 'проезд Дуйсена Суйесинова',
          kk: 'Дүйсен Сүйесінов өткелі',
        ),
        reverse,
        LocalizedNames(
          en: 'Garifolla Kurmangalieva St',
          ru: 'улица Гарифолла Курмангалиева',
          kk: 'Гарифолла Құрманғалиев көшесі',
        ),
      ];

      final choice = choosePinStreets(
        reverseStreet: reverse,
        tileStreets: tiles,
      );

      expect(choice.options.length, 3);
      expect(choice.selected.ru, 'улица Александра Афанасьева');
    },
  );

  test('choosePinStreets inserts reverse when tiles do not contain it', () {
    const reverse = LocalizedNames(ru: 'улица Ленина');
    const tiles = [LocalizedNames(ru: 'проезд Дуйсена Суйесинова')];

    final choice = choosePinStreets(reverseStreet: reverse, tileStreets: tiles);

    expect(choice.selected.ru, 'улица Ленина');
    expect(choice.selected.en, '');
    expect(choice.selected.kk, '');
    expect(choice.options.first.ru, 'улица Ленина');
    expect(choice.options.length, 2);
  });
}
