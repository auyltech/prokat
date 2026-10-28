import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';

void main() {
  group('parseRateOption', () {
    test('keeps historic codes', () {
      expect(parseRateOption('PER_HOUR').value, 'PER_HOUR');
      expect(parseRateOption('per_day').value, 'PER_DAY');
    });

    test('preserves unknown codes instead of remapping to PER_TRIP', () {
      expect(parseRateOption('PER_MONTH').value, 'PER_MONTH');
      expect(parseRateOption('PER_TONNE').value, 'PER_TONNE');
      expect(parseRateOption('PER_WEEK').value, isNot('PER_TRIP'));
    });

    test('PriceEntry.fromJson keeps new tariff codes', () {
      final entry = PriceEntry.fromJson({
        'id': 'p1',
        'price': 15000,
        'priceRate': 'PER_MONTH',
      });
      expect(entry.priceRate.value, 'PER_MONTH');
    });

    test('empty/null still uses first historic option', () {
      expect(parseRateOption(null).value, priceRateOptions.first.value);
      expect(parseRateOption('').value, priceRateOptions.first.value);
    });
  });
}
