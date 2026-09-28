import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_share/equipment_share_booking_intent.dart';
import 'package:prokat/features/locations/models/location_model.dart';

void main() {
  LocationModel address({
    String? id,
    String street = 'Сатыбалдиева',
    String city = 'Атырау',
    String country = 'Казахстан',
    String? houseNumber,
    String? comment,
    String? instructions,
    double latitude = 47.1,
    double longitude = 51.9,
  }) {
    return LocationModel(
      id: id,
      service: 'ADDRESS',
      street: street,
      city: city,
      country: country,
      houseNumber: houseNumber,
      comment: comment,
      instructions: instructions,
      latitude: latitude,
      longitude: longitude,
    );
  }

  EquipmentShareBookingIntent intent({LocationModel? addressModel}) {
    return EquipmentShareBookingIntent(
      userId: null,
      equipmentId: 'eq-1',
      priceEntryId: 'price-1',
      priceSnapshot: 15000,
      comment: 'к подъезду',
      scheduleMode: 'scheduled',
      bookedOn: DateTime.utc(2026, 9, 25),
      bookedAt: DateTime.utc(2026, 9, 25, 10),
      address: addressModel ?? address(),
    );
  }

  test('round-trip keeps the form and has no phone', () {
    final raw = jsonEncode(intent().toJson());
    final parsed = EquipmentShareBookingIntent.tryParse(raw);

    expect(parsed, isNotNull);
    expect(parsed!.userId, isNull);
    expect(parsed.equipmentId, 'eq-1');
    expect(parsed.address.street, 'Сатыбалдиева');
    expect(parsed.address.id, isNull);
    expect(raw.contains('phone'), isFalse);
  });

  test('address with id survives intent round-trip', () {
    final raw = jsonEncode(intent(addressModel: address(id: 'loc-1')).toJson());
    final parsed = EquipmentShareBookingIntent.tryParse(raw);
    expect(parsed!.address.id, 'loc-1');
  });

  test('corrupt json is dropped', () {
    expect(EquipmentShareBookingIntent.tryParse('{'), isNull);
    expect(EquipmentShareBookingIntent.tryParse('{"equipmentId":"x"}'), isNull);
  });

  test('another account discards the form', () {
    expect(
      decideShareIntent(
        intent: EquipmentShareBookingIntent(
          userId: 'user-a',
          equipmentId: 'eq-1',
          priceEntryId: 'price-1',
          priceSnapshot: 15000,
          comment: 'к подъезду',
          scheduleMode: 'scheduled',
          bookedOn: DateTime.utc(2026, 9, 25),
          bookedAt: DateTime.utc(2026, 9, 25, 10),
          address: address(),
        ),
        equipmentId: 'eq-1',
        currentUserId: 'user-b',
      ),
      ShareIntentDecision.discard,
    );
  });

  test('guest intent restores for the same equipment', () {
    expect(
      decideShareIntent(
        intent: intent(),
        equipmentId: 'eq-1',
        currentUserId: 'user-b',
      ),
      ShareIntentDecision.apply,
    );
    expect(
      decideShareIntent(
        intent: intent(),
        equipmentId: 'eq-2',
        currentUserId: 'user-b',
      ),
      ShareIntentDecision.skip,
    );
  });

  test('price drift keeps the tariff, a missing tariff does not', () {
    expect(
      shareTariffNotice(
        tariffExists: true,
        snapshot: 15000,
        currentPrice: 18000,
      ),
      ShareTariffNotice.changed,
    );
    expect(
      shareTariffNotice(
        tariffExists: false,
        snapshot: 15000,
        currentPrice: null,
      ),
      ShareTariffNotice.missing,
    );
  });

  group('sameSavedAddress', () {
    test('matches case and whitespace', () {
      expect(
        sameSavedAddress(
          address(street: '  Сатыбалдиева  ', city: 'атырау'),
          address(id: '1', street: 'сатыбалдиева', city: 'Атырау'),
        ),
        isTrue,
      );
    });

    test('rejects a different house', () {
      expect(
        sameSavedAddress(
          address(houseNumber: '10'),
          address(id: '1', houseNumber: '12'),
        ),
        isFalse,
      );
    });

    test('rejects a different city', () {
      expect(
        sameSavedAddress(address(city: 'Актау'), address(id: '1')),
        isFalse,
      );
    });

    test('rejects empty city or street', () {
      expect(
        sameSavedAddress(address(street: ''), address(id: '1', street: '')),
        isFalse,
      );
    });

    test('uses coordinates when both houses are empty', () {
      expect(
        sameSavedAddress(
          address(latitude: 47.1000, longitude: 51.9000),
          address(id: '1', latitude: 47.1001, longitude: 51.9001),
        ),
        isTrue,
      );
      expect(
        sameSavedAddress(
          address(latitude: 47.1, longitude: 51.9),
          address(id: '1', latitude: 47.2, longitude: 52.0),
        ),
        isFalse,
      );
    });

    test('house on only one side does not match even when close', () {
      expect(
        sameSavedAddress(
          address(houseNumber: '10', latitude: 47.1, longitude: 51.9),
          address(id: '1', latitude: 47.1, longitude: 51.9),
        ),
        isFalse,
      );
    });

    test('different non-empty comments do not match', () {
      expect(
        sameSavedAddress(
          address(houseNumber: '10', comment: 'подъезд 1'),
          address(id: '1', houseNumber: '10', comment: 'подъезд 2'),
        ),
        isFalse,
      );
    });

    test('different instructions still match', () {
      expect(
        sameSavedAddress(
          address(houseNumber: '10', instructions: 'позвонить'),
          address(id: '1', houseNumber: '10', instructions: 'не звонить'),
        ),
        isTrue,
      );
    });

    test('matchSavedAddress returns the persisted model with id', () {
      final matched = matchSavedAddress(address(houseNumber: '10'), [
        address(id: 'loc-9', houseNumber: '10'),
      ]);
      expect(matched?.id, 'loc-9');
    });
  });
}
