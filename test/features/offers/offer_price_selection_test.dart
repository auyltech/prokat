import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/offer_price_selection.dart';

void main() {
  test('default retains API order and does not mutate its input', () {
    final offers = [
      _offer('expensive', 300),
      _offer('cheap', 100),
      _offer('handled', 1, status: OfferStatus.accepted),
    ];
    final selection = OfferPriceSelection(offers);
    expect(selection.visible().map((offer) => offer.id), [
      'expensive',
      'cheap',
    ]);
    expect(
      selection
          .visible(order: OfferPriceOrder.lowestFirst)
          .map((offer) => offer.id),
      ['cheap', 'expensive'],
    );
    expect(offers.map((offer) => offer.id), ['expensive', 'cheap', 'handled']);
  });

  test('ties all qualify and stable sorting keeps their API order', () {
    final selection = OfferPriceSelection([
      _offer('b', 100),
      _offer('high', 300),
      _offer('a', 100),
    ]);
    expect(selection.bestIds, {'a', 'b'});
    expect(selection.visible(bestOnly: true).map((offer) => offer.id), [
      'b',
      'a',
    ]);
    expect(
      selection
          .visible(order: OfferPriceOrder.highestFirst)
          .map((offer) => offer.id),
      ['high', 'b', 'a'],
    );
  });

  test(
    'missing, zero, negative and unknown units never win or become zero',
    () {
      final selection = OfferPriceSelection([
        _offer('missing', 1, unit: null),
        _offer('valid', 200),
        _offer('zero', 0),
        _offer('negative', -10),
        _offer('unknown', 1, unit: 'BANANA'),
      ]);
      expect(selection.bestIds, {'valid'});
      expect(
        selection
            .visible(order: OfferPriceOrder.lowestFirst)
            .map((offer) => offer.id),
        ['valid', 'missing', 'zero', 'negative', 'unknown'],
      );
    },
  );

  test('mixed rates require a unit before sorting or choosing the minimum', () {
    final offers = [
      _offer('hour', 100, unit: 'PER_HOUR'),
      _offer('trip', 5),
      _offer('hour-cheap', 80, unit: 'PER_HOUR'),
    ];
    final all = OfferPriceSelection(offers);
    expect(all.canCompare, isFalse);
    expect(all.bestIds, isEmpty);
    expect(
      all.visible(order: OfferPriceOrder.lowestFirst).map((offer) => offer.id),
      ['hour', 'trip', 'hour-cheap'],
    );
    final hours = OfferPriceSelection(offers, selectedUnit: 'PER_HOUR');
    expect(hours.bestIds, {'hour-cheap'});
    expect(
      hours
          .visible(order: OfferPriceOrder.lowestFirst, selectedUnit: 'PER_HOUR')
          .map((offer) => offer.id),
      ['hour-cheap', 'hour'],
    );
  });

  test('terminal offers are never comparable and empty data stays empty', () {
    final selection = OfferPriceSelection([
      for (final status in OfferStatus.values)
        _offer(
          status.name,
          status == OfferStatus.created ? 200 : 100,
          status: status,
        ),
    ]);
    expect(selection.pending.map((offer) => offer.id), ['created', 'viewed']);
    expect(selection.bestIds, {'viewed'});
    final empty = OfferPriceSelection([]);
    expect(empty.canCompare, isFalse);
    expect(empty.visible(bestOnly: true), isEmpty);
  });
}

OfferModel _offer(
  String id,
  int price, {
  String? unit = 'PER_TRIP',
  OfferStatus status = OfferStatus.created,
}) => OfferModel(
  id: id,
  status: status,
  requestId: 'request',
  chatId: 'chat-$id',
  equipmentId: 'equipment',
  price: price,
  priceRate: unit == null ? null : PriceRateOption(value: unit, label: unit),
);
