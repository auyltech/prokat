import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';

void main() {
  test('request schedule is parsed locally and serialized as UTC', () {
    const requiredOnJson = '2026-08-05T00:00:00.000Z';
    const requiredAtJson = '2026-08-05T08:30:00.000Z';

    final request = RequestModel.fromJson({
      'id': 'request-1',
      'status': 'CREATED',
      'capacity': '10',
      'offeredPrice': 15000,
      'offeredPriceRate': 'PER_TRIP',
      'requiredOn': requiredOnJson,
      'requiredAt': requiredAtJson,
      'location': {
        'id': 'location-1',
        'service': 'ADDRESS',
        'street': 'Test street',
        'city': 'Qyzylorda',
        'country': 'Kazakhstan',
        'latitude': 44.8488,
        'longitude': 65.4823,
      },
    });

    expect(request.requiredOn, DateTime.parse(requiredOnJson).toLocal());
    expect(request.requiredAt, DateTime.parse(requiredAtJson).toLocal());
    expect(request.requiredOn?.isUtc, isFalse);
    expect(request.requiredAt?.isUtc, isFalse);

    final serialized = request.toJson();
    expect(serialized['requiredOn'], requiredOnJson);
    expect(serialized['requiredAt'], requiredAtJson);
  });

  test('parses client request when location and client are null', () {
    final request = RequestModel.fromJson({
      'id': '320fff4d-3178-4be1-8c21-3eba829eb8f5',
      'status': 'RESPONDED',
      'capacity': 5,
      'offeredPrice': 1000,
      'offeratePriceRate': '',
      'comment': '',
      'requiredOn': '2026-08-27T00:00:00.000Z',
      'requiredAt': '2026-08-27T12:00:00.000Z',
      'createdAt': '2026-08-26T07:17:35.502Z',
      'updatedAt': '2026-08-26T07:44:25.760Z',
      'didSendOffer': false,
      'hasActiveOffer': false,
      'offersCount': 0,
      'client': null,
      'category': {
        'id': 'ad5b653f-310b-4040-ae4e-d24587e7d209',
        'name': 'Вакуумные машины',
        'names': {
          'en': 'Vacuum Trucks',
          'ru': 'Вакуумные машины',
          'kk': 'Вакуумдық машиналар',
        },
        'slug': 'vacuum_trucks',
        'imageUrl': 'https://example.com/category.png',
        'sortIndex': 1,
      },
      'location': null,
    });

    expect(request.id, '320fff4d-3178-4be1-8c21-3eba829eb8f5');
    expect(request.status, RequestStatus.responded);
    expect(request.capacity, '5');
    expect(request.offeredPrice, 1000);
    expect(request.location, isNull);
    expect(request.client, isNull);
    expect(request.category?.id, 'ad5b653f-310b-4040-ae4e-d24587e7d209');
  });

  test('treats malformed location payload as missing', () {
    final request = RequestModel.fromJson({
      'id': 'request-2',
      'status': 'CREATED',
      'capacity': '1',
      'offeredPrice': 0,
      'location': {
        'id': 'location-2',
        'street': 'Broken',
        'city': 'Atyrau',
        'country': 'KZ',
      },
    });

    expect(request.location, isNull);
  });
}
