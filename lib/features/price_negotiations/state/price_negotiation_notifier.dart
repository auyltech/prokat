import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';

class PriceNegotiationNotifier extends StateNotifier<PriceNegotiationState> {
  final PriceNegotiationService service;

  PriceNegotiationNotifier(this.service) : super(const PriceNegotiationState());

  bool isLatestPendingFromMe(String? currentUserId) {
    final pending = state.latestPending;
    final userId = (currentUserId ?? '').trim();

    if (pending == null || userId.isEmpty) return false;
    return (pending.senderId ?? '').trim() == userId;
  }

  PriceNegotiation? getPendingNegotiation({
    String? bookingId,
    String? offerId,
    String? currentUserId,
    String? mode,
  }) {
    if (bookingId != null) {
      print(state.negotiations.length);
      final found = state.negotiations
          .where(
            (item) =>
                (item.bookingId == bookingId) &&
                (item.status == PriceNegotiationStatus.pending),
          )
          .firstOrNull;

      return found;
    } else if (offerId != null) {
      final found = state.negotiations
          .where(
            (item) =>
                item.offerId == offerId &&
                item.status == PriceNegotiationStatus.pending,
          )
          .firstOrNull;

      return found;
    } else {
      return null;
    }
  }

  Future<void> getPriceNegotiations() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await service.getPriceNegotiations();

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
    String? bookingId,
    String? offerId,
    String? priceRate,
    String? comment,
    required String type,
  }) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      await service.createPriceNegotiation(
        bookingId: bookingId,
        offerId: offerId,
        price: price,
        priceRate: priceRate,
        comment: comment,
        type: type,
      );

      state = state.copyWith(isSubmitting: false);

      await getPriceNegotiations();
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

      await getPriceNegotiations();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      rethrow;
    }
  }
}
