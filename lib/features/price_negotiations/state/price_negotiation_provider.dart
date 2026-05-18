import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/api_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';

final priceNegotiationServiceProvider = Provider<PriceNegotiationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PriceNegotiationService(apiClient);
});

final priceNegotiationByBookingProvider =
    StateNotifierProvider.family<PriceNegotiationNotifier, PriceNegotiationState, String>(
      (ref, bookingId) {
        final service = ref.read(priceNegotiationServiceProvider);
        return PriceNegotiationNotifier(service, PriceNegotiationScope.booking(bookingId));
      },
    );

final priceNegotiationByOfferProvider =
    StateNotifierProvider.family<PriceNegotiationNotifier, PriceNegotiationState, String>(
      (ref, offerId) {
        final service = ref.read(priceNegotiationServiceProvider);
        return PriceNegotiationNotifier(service, PriceNegotiationScope.offer(offerId));
      },
    );

