import 'dart:convert';
import 'dart:math' as math;

import 'package:prokat/features/locations/models/location_model.dart';

enum ShareIntentDecision { apply, discard, skip }

enum ShareTariffNotice { none, missing, changed }

class EquipmentShareBookingIntent {
  final String? userId;
  final String equipmentId;
  final String priceEntryId;
  final int priceSnapshot;
  final String comment;
  final String scheduleMode;
  final DateTime bookedOn;
  final DateTime bookedAt;
  final LocationModel address;

  const EquipmentShareBookingIntent({
    required this.userId,
    required this.equipmentId,
    required this.priceEntryId,
    required this.priceSnapshot,
    required this.comment,
    required this.scheduleMode,
    required this.bookedOn,
    required this.bookedAt,
    required this.address,
  });

  EquipmentShareBookingIntent copyWith({LocationModel? address}) {
    return EquipmentShareBookingIntent(
      userId: userId,
      equipmentId: equipmentId,
      priceEntryId: priceEntryId,
      priceSnapshot: priceSnapshot,
      comment: comment,
      scheduleMode: scheduleMode,
      bookedOn: bookedOn,
      bookedAt: bookedAt,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'equipmentId': equipmentId,
      'priceEntryId': priceEntryId,
      'priceSnapshot': priceSnapshot,
      'comment': comment,
      'scheduleMode': scheduleMode,
      'bookedOn': bookedOn.toUtc().toIso8601String(),
      'bookedAt': bookedAt.toUtc().toIso8601String(),
      'address': {...address.toJson(), 'id': address.id},
    };
  }

  static EquipmentShareBookingIntent? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = Map<String, dynamic>.from(decoded);
      final equipmentId = json['equipmentId']?.toString().trim() ?? '';
      final priceEntryId = json['priceEntryId']?.toString().trim() ?? '';
      final scheduleMode = json['scheduleMode']?.toString().trim() ?? '';
      final snapshot = json['priceSnapshot'];
      final priceSnapshot = snapshot is int
          ? snapshot
          : int.tryParse(snapshot?.toString() ?? '');
      final bookedOn = DateTime.tryParse(json['bookedOn']?.toString() ?? '');
      final bookedAt = DateTime.tryParse(json['bookedAt']?.toString() ?? '');
      final addressJson = json['address'];
      if (equipmentId.isEmpty ||
          priceEntryId.isEmpty ||
          priceSnapshot == null ||
          bookedOn == null ||
          bookedAt == null ||
          addressJson is! Map ||
          (scheduleMode != 'asap' && scheduleMode != 'scheduled')) {
        return null;
      }

      final userId = json['userId']?.toString().trim();
      return EquipmentShareBookingIntent(
        userId: userId == null || userId.isEmpty ? null : userId,
        equipmentId: equipmentId,
        priceEntryId: priceEntryId,
        priceSnapshot: priceSnapshot,
        comment: json['comment']?.toString() ?? '',
        scheduleMode: scheduleMode,
        bookedOn: bookedOn.toLocal(),
        bookedAt: bookedAt.toLocal(),
        address: LocationModel.fromJson(Map<String, dynamic>.from(addressJson)),
      );
    } catch (_) {
      return null;
    }
  }
}

ShareIntentDecision decideShareIntent({
  required EquipmentShareBookingIntent? intent,
  required String equipmentId,
  required String? currentUserId,
}) {
  if (intent == null || intent.equipmentId != equipmentId) {
    return ShareIntentDecision.skip;
  }
  final stored = intent.userId?.trim();
  final current = currentUserId?.trim();
  if (stored != null && stored.isNotEmpty && stored != current) {
    return ShareIntentDecision.discard;
  }
  return ShareIntentDecision.apply;
}

ShareTariffNotice shareTariffNotice({
  required bool tariffExists,
  required int? snapshot,
  required int? currentPrice,
}) {
  if (!tariffExists || currentPrice == null) return ShareTariffNotice.missing;
  if (snapshot != null && snapshot != currentPrice) {
    return ShareTariffNotice.changed;
  }
  return ShareTariffNotice.none;
}

String normalizeShareAddressPart(String? value) {
  final trimmed = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  return trimmed.toLowerCase();
}

const shareAddressMatchMeters = 50.0;

double shareAddressDistanceMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

bool sameSavedAddress(LocationModel pin, LocationModel saved) {
  final city = normalizeShareAddressPart(pin.city);
  final street = normalizeShareAddressPart(pin.street);
  final savedCity = normalizeShareAddressPart(saved.city);
  final savedStreet = normalizeShareAddressPart(saved.street);

  if (city.isEmpty ||
      street.isEmpty ||
      savedCity.isEmpty ||
      savedStreet.isEmpty) {
    return false;
  }
  if (city != savedCity || street != savedStreet) return false;

  final country = normalizeShareAddressPart(pin.country);
  final savedCountry = normalizeShareAddressPart(saved.country);
  if (country.isNotEmpty &&
      savedCountry.isNotEmpty &&
      country != savedCountry) {
    return false;
  }

  final house = normalizeShareAddressPart(pin.houseNumber);
  final savedHouse = normalizeShareAddressPart(saved.houseNumber);
  if (house.isNotEmpty && savedHouse.isNotEmpty) {
    if (house != savedHouse) return false;
  } else if (house.isNotEmpty || savedHouse.isNotEmpty) {
    return false;
  }

  final comment = normalizeShareAddressPart(pin.comment);
  final savedComment = normalizeShareAddressPart(saved.comment);
  if (comment.isNotEmpty &&
      savedComment.isNotEmpty &&
      comment != savedComment) {
    return false;
  }

  if (house.isEmpty && savedHouse.isEmpty) {
    if (!_isValidLatLon(pin.latitude, pin.longitude) ||
        !_isValidLatLon(saved.latitude, saved.longitude)) {
      return false;
    }
    final meters = shareAddressDistanceMeters(
      lat1: pin.latitude,
      lon1: pin.longitude,
      lat2: saved.latitude,
      lon2: saved.longitude,
    );
    if (meters > shareAddressMatchMeters) return false;
  }

  return true;
}

bool _isValidLatLon(double lat, double lon) {
  if (lat.isNaN || lon.isNaN) return false;
  if (lat < -90 || lat > 90) return false;
  if (lon < -180 || lon > 180) return false;
  return true;
}

LocationModel? matchSavedAddress(LocationModel pin, List<LocationModel> saved) {
  for (final item in saved) {
    if (sameSavedAddress(pin, item) && (item.id ?? '').trim().isNotEmpty) {
      return item;
    }
  }
  return null;
}
