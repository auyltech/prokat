import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';

enum PriceNegotiationScopeType { booking, offer }

class PriceNegotiationScope {
  final PriceNegotiationScopeType type;
  final String id;

  const PriceNegotiationScope.booking(this.id)
    : type = PriceNegotiationScopeType.booking;
  const PriceNegotiationScope.offer(this.id)
    : type = PriceNegotiationScopeType.offer;
}

class PriceNegotiationNotifier extends StateNotifier<PriceNegotiationState> {
  final PriceNegotiationService service;
  final PriceNegotiationScope scope;

  PriceNegotiationNotifier(this.service, this.scope)
    : super(const PriceNegotiationState()) {
    refresh();
  }

  bool isLatestPendingFromMe(String? currentUserId) {
    final pending = state.latestPending;
    final userId = (currentUserId ?? '').trim();
    if (pending == null || userId.isEmpty) return false;
    return (pending.senderId ?? '').trim() == userId;
  }

  Future<void> refresh() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await service.getPriceNegotiations(scope.id);

      if (result.success) {
        final sorted = List<PriceNegotiation>.from(result.data?.toList() ?? []);

        sorted.sort((a, b) {
          final aDate = a.createdAt ?? DateTime(1970);
          final bDate = b.createdAt ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });

        state = state.copyWith(
          isLoading: false,
          negotiations: sorted,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        negotiations: const [],
        error: e.toString(),
      );
    }
  }

  Future<void> createCounterOffer({
    required int price,
    String? priceRate,
    String? comment,
    required String type,
  }) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      await service.createPriceNegotiation(
        bookingId: scope.type == PriceNegotiationScopeType.booking
            ? scope.id
            : null,
        offerId: scope.type == PriceNegotiationScopeType.offer
            ? scope.id
            : null,
        price: price,
        priceRate: priceRate,
        comment: comment,
        type: type,
      );

      state = state.copyWith(isSubmitting: false);

      await refresh();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> respond({
    required String negotiationId,
    required PriceNegotiationResponse response,
  }) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      await service.respondToPriceNegotiation(
        negotiationId: negotiationId,
        decision: response,
      );

      state = state.copyWith(isSubmitting: false);

      // Refresh is called by the booking notifier
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> cancelNegotiation(String negotiationId) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      await service.cancelPriceNegotiation(negotiationId);
      state = state.copyWith(isSubmitting: false);

      await refresh();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }
}
