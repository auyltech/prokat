import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_state.dart';

class PriceNegotiationNotifier extends StateNotifier<PriceNegotiationState> {
  final PriceNegotiationService service;

  PriceNegotiationNotifier(this.service) : super(const PriceNegotiationState());

  // Helper Method
  bool isLatestPendingFromMe(String? currentUserId) {
    final pending = state.latestPending;
    final userId = (currentUserId ?? '').trim();

    if (pending == null || userId.isEmpty) return false;
    return (pending.senderId ?? '').trim() == userId;
  }

  // Helper Method
  PriceNegotiation? getPendingNegotiation({
    String? bookingId,
    String? offerId,
    String? currentUserId,
    String? mode,
  }) {
    if (bookingId != null) {
      final found = state.negotiations
          .where(
            (item) =>
                (item.bookingId == bookingId) &&
                (item.status == PriceNegotiationStatus.created),
          )
          .firstOrNull;

      return found;
    } else if (offerId != null) {
      final found = state.negotiations
          .where(
            (item) =>
                item.offerId == offerId &&
                item.status == PriceNegotiationStatus.created,
          )
          .firstOrNull;

      return found;
    } else {
      return null;
    }
  }

  // Fetch Price Negotiations
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
      state = state.copyWith(
        isSubmitting: true,
        actionId: "price:create",
        error: null,
      );

      final result = await service.createPriceNegotiation(
        bookingId: bookingId,
        offerId: offerId,
        price: price,
        priceRate: priceRate,
        comment: comment,
        type: type,
      );

      state = state.copyWith(
        isSubmitting: false,
        error: result.success ? null : result.message,
        actionId: null,
      );

      if (result.success) {
        await getPriceNegotiations();
      }
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: error.toString(),
        actionId: null,
      );
    }
  }

  Future<void> respondToPriceNegotiation({
    required String negotiationId,
    required PriceNegotiationResponse response,
  }) async {
    try {
      state = state.copyWith(
        isSubmitting: true,
        actionId: response == PriceNegotiationResponse.accept
            ? "price:accept"
            : "price:reject",
        error: null,
      );

      final result = await service.respondToPriceNegotiation(
        negotiationId: negotiationId,
        decision: response,
      );

      state = state.copyWith(
        isSubmitting: false,
        error: result.success ? null : result.message,
        actionId: null,
      );

      // Refresh is called by the booking notifier
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
        actionId: null,
      );
    }
  }

  Future<void> cancelPriceNegotiation(String negotiationId) async {
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
