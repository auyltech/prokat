import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';

void main() {
  test('all existing offer units retain their contract', () {
    for (final unit in priceRateOptions) {
      final offer = OfferModel.fromJson({
        'id': 'offer',
        'status': 'CREATED',
        'price': 18000,
        'priceRate': unit.value.toLowerCase(),
      });
      expect(offer.priceRate?.value, unit.value);
      expect(offer.price, 18000);
    }
  });

  test('missing and future offer units never become trip prices', () {
    for (final value in [null, '', 'PER_WEEK', 'unknown']) {
      final offer = OfferModel.fromJson({
        'id': 'offer',
        'status': 'CREATED',
        'price': 18000,
        'priceRate': value,
      });
      expect(offer.priceRate, isNull);
    }
    expect(parseRateOption(null).value, 'PER_TRIP');
  });

  test('live request DTO budget remains amount-only', () {
    final request = RequestModel.fromJson({
      'id': 'request',
      'status': 'RESPONDED',
      'capacity': 0,
      'offeredPrice': 25000,
      'offeratePriceRate': '',
    });
    expect(request.offeredPrice, 25000);
    expect(request.offeredPriceRate, isNull);
    final legacy = RequestModel.fromJson({
      'id': 'request',
      'status': 'RESPONDED',
      'offeredPrice': 25000,
      'offeredPriceRate': 'PER_HOUR',
    });
    expect(legacy.offeredPriceRate?.value, 'PER_HOUR');
  });
}
