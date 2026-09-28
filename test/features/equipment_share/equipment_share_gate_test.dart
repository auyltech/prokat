import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment_share/equipment_share_gate.dart';
import 'package:prokat/features/equipment_share/equipment_share_message.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

Equipment _equipment({
  EquipmentStatus status = EquipmentStatus.available,
  bool isVisible = true,
  List<PriceEntry> prices = const [],
  String? rentCondition,
  String? ownerComment,
}) {
  return Equipment(
    id: 'eq-1',
    name: 'Илосос',
    model: 'MB',
    status: status,
    isVisible: isVisible,
    prices: prices,
    rentCondition: rentCondition,
    ownerComment: ownerComment,
  );
}

PriceEntry _price(int price, {bool isStartingFrom = false}) {
  return PriceEntry(
    id: 'price-$price',
    price: price,
    priceRate: const PriceRateOption(value: 'PER_HOUR', label: 'Per Hour'),
    isStartingFrom: isStartingFrom,
  );
}

void main() {
  final l10n = AppLocalizationsRu();

  group('share gates', () {
    test('hides the button before moderation and for archived', () {
      for (final status in [
        EquipmentStatus.draft,
        EquipmentStatus.created,
        EquipmentStatus.rejected,
        EquipmentStatus.archived,
      ]) {
        final equipment = _equipment(status: status, prices: [_price(12000)]);
        expect(canShowShareButton(equipment), isFalse, reason: status.name);
        expect(needsPublishAlert(equipment), isFalse, reason: status.name);
        expect(isShareableNow(equipment), isFalse, reason: status.name);
      }
    });

    test('shows a publish alert for moderated equipment that is not in the catalog', () {
      for (final status in [
        EquipmentStatus.accepted,
        EquipmentStatus.booked,
        EquipmentStatus.maintenance,
        EquipmentStatus.disabled,
      ]) {
        final equipment = _equipment(status: status, prices: [_price(12000)]);
        expect(canShowShareButton(equipment), isTrue, reason: status.name);
        expect(needsPublishAlert(equipment), isTrue, reason: status.name);
        expect(isShareableNow(equipment), isFalse, reason: status.name);
      }

      final hidden = _equipment(isVisible: false, prices: [_price(12000)]);
      expect(canShowShareButton(hidden), isTrue);
      expect(needsPublishAlert(hidden), isTrue);
      expect(isShareableNow(hidden), isFalse);

      final noPrice = _equipment(prices: [_price(0)]);
      expect(canShowShareButton(noPrice), isTrue);
      expect(needsPublishAlert(noPrice), isTrue);
      expect(isShareableNow(noPrice), isFalse);
    });

    test('shares only available visible equipment with a positive price', () {
      final equipment = _equipment(prices: [_price(0), _price(12000)]);
      expect(canShowShareButton(equipment), isTrue);
      expect(needsPublishAlert(equipment), isFalse);
      expect(isShareableNow(equipment), isTrue);
    });
  });

  group('share text', () {
    test('uses the first positive price and skips an empty description', () {
      final equipment = _equipment(
        prices: [_price(0), _price(12000)],
        ownerComment: '   ',
      );

      expect(shareDescriptionOf(equipment), isNull);
      expect(sharePriceLine(equipment, l10n), '12 000 ₸ / час');
      expect(
        equipmentShareMessage(
          l10n,
          name: equipment.name,
          priceLine: sharePriceLine(equipment, l10n)!,
          url: Env.equipmentShareUrl(equipment.id),
        ),
        'Илосос\n12 000 ₸ / час\nhttps://prokat-bfbec.web.app/e/eq-1',
      );
    });

    test('marks a starting price and prefers the rent condition', () {
      final equipment = _equipment(
        prices: [_price(12000, isStartingFrom: true)],
        rentCondition: 'С водителем',
        ownerComment: 'Не показывать',
      );

      expect(shareDescriptionOf(equipment), 'С водителем');
      expect(sharePriceLine(equipment, l10n), 'от 12 000 ₸ / час');
    });
  });
}
