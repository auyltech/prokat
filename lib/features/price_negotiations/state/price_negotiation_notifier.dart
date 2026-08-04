import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/mutation/mutation_notifier.dart';
import 'package:prokat/features/bookings/models/booking_lookup.dart';
import 'package:prokat/features/bookings/providers/booking_provider.dart';
import 'package:prokat/features/chat/state/post_mutation_cache_coordinator.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';

class PriceNegotiationMutationNotifier
    extends MutationNotifier<PriceNegotiationState> {
  PriceNegotiationMutationNotifier(this.ref, this.service)
    : super(const PriceNegotiationState());

  final Ref ref;
  final PriceNegotiationService service;

  PostMutationCacheCoordinator get _cacheCoordinator =>
      ref.read(postMutationCacheCoordinatorProvider);

  @override
  Set<Mutation> get activeActions => state.activeActions;

  @override
  PriceNegotiationState copyState({Set<Mutation>? activeActions}) =>
      state.copyWith(activeActions: activeActions);

  PriceNegotiationQuery? _queryFor({String? bookingId, String? offerId}) {
    final booking = (bookingId ?? '').trim();
    final offer = (offerId ?? '').trim();
    if ((booking.isNotEmpty) == (offer.isNotEmpty)) return null;
    return PriceNegotiationQuery(
      bookingId: booking.isEmpty ? null : booking,
      offerId: offer.isEmpty ? null : offer,
      filter: PriceNegotiationListFilter.active,
    );
  }

  Future<void> _syncQueries(PriceNegotiationQuery query) async {
    final updates = <Future<void>>[];
    final active = priceNegotiationsProvider(query);
    if (ref.exists(active)) {
      updates.add(ref.read(active.notifier).refresh());
    }

    final history = priceNegotiationsProvider(
      query.withFilter(PriceNegotiationListFilter.history),
    );
    if (ref.exists(history)) {
      updates.add(ref.read(history.notifier).invalidate());
    }
    await Future.wait(updates);
  }

  Future<void> _refreshSubject(PriceNegotiationQuery query) async {
    final refreshes = <Future<void>>[];
    final bookingId = query.bookingId;
    if (bookingId != null) {
      for (final isOwner in [false, true]) {
        final provider = bookingProvider(
          BookingLookup(bookingId: bookingId, isOwner: isOwner),
        );
        if (ref.exists(provider)) {
          ref.invalidate(provider);
        }
      }
    } else {
      for (final provider in [
        clientOffersProvider(const OfferQuery.active()),
        ownerOffersProvider(const OfferQuery.active()),
      ]) {
        if (ref.exists(provider)) {
          refreshes.add(ref.read(provider.notifier).refresh());
        }
      }
    }
    await Future.wait(refreshes);
  }

  Future<void> createCounterOffer({
    required int price,
    String? bookingId,
    String? offerId,
    String? priceRate,
    String? comment,
    required String type,
    String? chatId,
  }) async {
    const actionId = 'price:create';
    final query = _queryFor(bookingId: bookingId, offerId: offerId);
    if (query == null) {
      throw Exception('Provide exactly one bookingId or offerId');
    }
    startAction(actionId);
    try {
      final result = await service.createPriceNegotiation(
        bookingId: bookingId,
        offerId: offerId,
        price: price,
        priceRate: priceRate,
        comment: comment,
        type: type,
      );
      finishAction(
        actionId,
        error: result.success ? null : _error(result.message),
      );
      if (!result.success) throw Exception(result.message);
      await Future.wait([
        _syncQueries(query),
        _refreshSubject(query),
        _cacheCoordinator.refreshAffectedChats(chatId),
      ]);
    } catch (error) {
      finishAction(actionId, error: _error(error.toString()));
      rethrow;
    }
  }

  Future<void> respondToPriceNegotiation({
    required String negotiationId,
    required PriceNegotiationResponse response,
    String? bookingId,
    String? offerId,
    String? chatId,
  }) async {
    final actionId = response == PriceNegotiationResponse.accept
        ? 'price:accept'
        : 'price:reject';
    startAction(actionId);
    try {
      final result = await service.respondToPriceNegotiation(
        negotiationId: negotiationId,
        decision: response,
      );
      finishAction(
        actionId,
        error: result.success ? null : _error(result.message),
      );
      if (!result.success) throw Exception(result.message);
      final query = _queryFor(bookingId: bookingId, offerId: offerId);
      if (query != null) {
        await Future.wait([
          _syncQueries(query),
          _refreshSubject(query),
          _cacheCoordinator.refreshAffectedChats(chatId),
        ]);
      } else {
        await _cacheCoordinator.refreshAffectedChats(chatId);
      }
    } catch (error) {
      finishAction(actionId, error: _error(error.toString()));
      rethrow;
    }
  }

  Future<void> cancelPriceNegotiation(
    String negotiationId, {
    String? bookingId,
    String? offerId,
    String? chatId,
  }) async {
    final actionId = 'price:cancel:$negotiationId';
    startAction(actionId);
    try {
      final result = await service.cancelPriceNegotiation(negotiationId);
      finishAction(
        actionId,
        error: result.success ? null : _error(result.message),
      );
      if (!result.success) throw Exception(result.message);
      final query = _queryFor(bookingId: bookingId, offerId: offerId);
      if (query != null) {
        await Future.wait([
          _syncQueries(query),
          _refreshSubject(query),
          _cacheCoordinator.refreshAffectedChats(chatId),
        ]);
      } else {
        await _cacheCoordinator.refreshAffectedChats(chatId);
      }
    } catch (error) {
      finishAction(actionId, error: _error(error.toString()));
      rethrow;
    }
  }

  AppError _error(String message) => AppError(
    type: ErrorType.unknown,
    code: 'PRICE_NEGOTIATION_FAILED',
    message: message,
  );
}
