import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';

enum OfferPriceOrder { original, lowestFirst, highestFirst }

/// Local presentation only. A trip and an hour are never compared by amount.
class OfferPriceSelection {
  final List<OfferModel> pending;
  final List<PriceRateOption> units;
  final String? effectiveUnit;

  OfferPriceSelection(Iterable<OfferModel> offers, {String? selectedUnit})
    : pending = List.unmodifiable(offers.where(isPending)),
      units = List.unmodifiable(
        priceRateOptions.where(
          (unit) => offers.any(
            (offer) =>
                isPending(offer) &&
                offer.price > 0 &&
                offer.priceRate?.value == unit.value,
          ),
        ),
      ),
      effectiveUnit = _resolveUnit(offers, selectedUnit);

  static bool isPending(OfferModel offer) =>
      offer.status == OfferStatus.created || offer.status == OfferStatus.viewed;

  static String? _resolveUnit(Iterable<OfferModel> offers, String? selected) {
    final values = offers
        .where(isPending)
        .where((offer) => offer.price > 0)
        .map((offer) => offer.priceRate?.value)
        .where((value) => priceRateOptions.any((unit) => unit.value == value))
        .toSet();
    if (selected != null && values.contains(selected)) return selected;
    return values.length == 1 ? values.single : null;
  }

  bool get canCompare => effectiveUnit != null;

  Set<String> get bestIds {
    if (!canCompare) return const {};
    final comparable = pending.where(
      (offer) => offer.price > 0 && offer.priceRate?.value == effectiveUnit,
    );
    if (comparable.isEmpty) return const {};
    final minimum = comparable
        .map((offer) => offer.price)
        .reduce((a, b) => a < b ? a : b);
    // Equal prices have equal status. Never choose one owner arbitrarily.
    return comparable
        .where((offer) => offer.price == minimum)
        .map((offer) => offer.id)
        .toSet();
  }

  List<OfferModel> visible({
    OfferPriceOrder order = OfferPriceOrder.original,
    bool bestOnly = false,
    String? selectedUnit,
  }) {
    final selectedExists = units.any((unit) => unit.value == selectedUnit);
    final result = pending
        .where(
          (offer) => !selectedExists || offer.priceRate?.value == selectedUnit,
        )
        .toList();
    if (!canCompare) return result;
    if (bestOnly) {
      final winners = bestIds;
      return result.where((offer) => winners.contains(offer.id)).toList();
    }
    if (order == OfferPriceOrder.original) return result;
    final originalIndex = <String, int>{
      for (var i = 0; i < result.length; i++) result[i].id: i,
    };
    result.sort((a, b) {
      final aValid = a.price > 0 && a.priceRate?.value == effectiveUnit;
      final bValid = b.price > 0 && b.priceRate?.value == effectiveUnit;
      if (aValid != bValid) return aValid ? -1 : 1;
      if (aValid) {
        final amount = order == OfferPriceOrder.lowestFirst
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price);
        if (amount != 0) return amount;
      }
      return originalIndex[a.id]!.compareTo(originalIndex[b.id]!);
    });
    return result;
  }
}
