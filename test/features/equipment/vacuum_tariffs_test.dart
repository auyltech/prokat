import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

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

  test('adoptServerTariffs deduplicates an acknowledged create', () {
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

  group('savedTariffTitle', () {
    final l10n = AppLocalizationsRu();

    PriceEntry entry(String? label) {
      return PriceEntry(
        id: 'p1',
        price: 12000,
        priceRate: priceRateOptions.first,
        label: label,
      );
    }

    test('localizes a known service key', () {
      expect(
        savedTariffTitle(entry(vacuumTariffSeptic), l10n),
        l10n.tariffSepticSewage,
      );
    });

    test('shows a free-form label as typed', () {
      expect(
        savedTariffTitle(entry('Мойка контейнеров'), l10n),
        'Мойка контейнеров',
      );
    });

    test('returns null when the owner never saved a label', () {
      expect(savedTariffTitle(entry(null), l10n), isNull);
      expect(savedTariffTitle(entry('   '), l10n), isNull);
      expect(savedTariffTitle(entry(vacuumTariffOther), l10n), isNull);
    });

    test('never returns the owner editor placeholder', () {
      expect(savedTariffTitle(entry(null), l10n), isNot(l10n.newRate));
    });
  });

  test(
    'a response without a new tariff does not discard its completed draft',
    () {
      final draft = TariffDraft(
        labelKey: vacuumTariffSeptic,
        price: 15000,
        priceRate: priceRateOptions.first,
        expanded: true,
      );
      final adopted = adoptServerTariffs(server: [], local: [draft]);
      expect(adopted, hasLength(1));
      expect(adopted.single.persistedLabel(), vacuumTariffSeptic);
      expect(adopted.single.price, 15000);
      expect(adopted.single.expanded, isTrue);
    },
  );
}
