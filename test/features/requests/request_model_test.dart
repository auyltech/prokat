import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/requests/models/request_model.dart';

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
}
