import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_notifier.dart';
import 'package:prokat/features/offers/state/offers_query_notifier.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/offers/state/offers_state.dart';

final offersServiceProvider = Provider<OffersService>((ref) {
  return OffersService(ref.watch(apiClientProvider));
});

final clientOffersProvider =
    AsyncNotifierProvider.family<
      ClientOffersNotifier,
      QueryState<OfferModel>,
      OfferQuery
    >(ClientOffersNotifier.new);

final ownerOffersProvider =
    AsyncNotifierProvider.family<
      OwnerOffersNotifier,
      QueryState<OfferModel>,
      OfferQuery
    >(OwnerOffersNotifier.new);

final offerMutationProvider =
    StateNotifierProvider<OfferMutationNotifier, OffersState>((ref) {
      return OfferMutationNotifier(
        service: ref.read(offersServiceProvider),
        ref: ref,
      );
    });
