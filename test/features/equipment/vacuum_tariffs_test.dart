import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';

Equipment _equipment({List<PriceEntry> prices = const []}) {
  return Equipment(
    id: 'eq-1',
    name: 'Truck',
    model: 'Kamaz',
    status: EquipmentStatus.draft,
    isVisible: true,
    categoryId: 'vacuum',
    prices: prices,
  );
}

void main() {
  test('tariffsForEditor starts empty and does not seed presets', () {
    expect(tariffsForEditor(_equipment(), vacuumCategoryId: 'vacuum'), isEmpty);
  });

  test('tariffsForEditor maps saved prices only', () {
    final drafts = tariffsForEditor(
      _equipment(
        prices: [
          PriceEntry(
            id: 'p1',
            price: 15000,
            priceRate: priceRateOptions.first,
            label: vacuumTariffSeptic,
          ),
        ],
      ),
    );

    expect(drafts, hasLength(1));
    expect(drafts.single.isPreset, isFalse);
    expect(drafts.single.labelKey, vacuumTariffSeptic);
    expect(drafts.single.price, 15000);
  });

  test('adoptServerTariffs does not keep savable drafts without id', () {
    final server = tariffsForEditor(
      _equipment(
        prices: [
          PriceEntry(
            id: 'p1',
            price: 15000,
            priceRate: priceRateOptions.first,
            label: vacuumTariffSeptic,
          ),
        ],
      ),
    );
    final localClone = TariffDraft(
      labelKey: vacuumTariffSeptic,
      price: 15000,
      priceRate: priceRateOptions.first,
    );
    final incomplete = TariffDraft.custom();

    final adopted = adoptServerTariffs(
      server: server,
      local: [localClone, incomplete],
    );

    expect(adopted, hasLength(2));
    expect(adopted.first.id, 'p1');
    expect(adopted.last.id, isNull);
    expect(adopted.last.isSavable, isFalse);
  });

  test('adoptServerTariffs keeps a tariff expanded after persist', () {
    final local = TariffDraft(
      labelKey: vacuumTariffSeptic,
      price: 15000,
      priceRate: priceRateOptions.first,
      expanded: true,
    );
    final server = [
      TariffDraft.fromEntry(
        PriceEntry(
          id: 'p1',
          price: 15000,
          priceRate: priceRateOptions.first,
          label: vacuumTariffSeptic,
        ),
      ),
    ];

    final adopted = adoptServerTariffs(server: server, local: [local]);
    expect(adopted, hasLength(1));
    expect(adopted.single.id, 'p1');
    expect(adopted.single.expanded, isTrue);
  });
}
