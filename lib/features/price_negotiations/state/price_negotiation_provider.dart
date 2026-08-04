import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiations_query_notifier.dart';

final priceNegotiationServiceProvider = Provider<PriceNegotiationService>((
  ref,
) {
  return PriceNegotiationService(ref.watch(apiClientProvider));
});

final priceNegotiationsProvider =
    AsyncNotifierProvider.family<
      PriceNegotiationsNotifier,
      QueryState<PriceNegotiation>,
      PriceNegotiationQuery
    >(PriceNegotiationsNotifier.new);

final priceNegotiationMutationProvider =
    StateNotifierProvider<
      PriceNegotiationMutationNotifier,
      PriceNegotiationState
    >((ref) {
      return PriceNegotiationMutationNotifier(
        ref,
        ref.read(priceNegotiationServiceProvider),
      );
    });
