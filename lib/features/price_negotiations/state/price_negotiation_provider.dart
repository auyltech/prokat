import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';

final priceNegotiationServiceProvider = Provider<PriceNegotiationService>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return PriceNegotiationService(apiClient);
});

final priceNegotiationProvider =
    StateNotifierProvider<PriceNegotiationNotifier, PriceNegotiationState>((
      ref,
    ) {
      final api = ref.read(priceNegotiationServiceProvider);

      return PriceNegotiationNotifier(api);
    });
