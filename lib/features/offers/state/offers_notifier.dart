import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/offers/state/offers_state.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class OffersNotifier extends StateNotifier<OffersState> {
  final OffersService service;

  OffersNotifier(this.service) : super(OffersState());

  void selectRequest(RequestModel request) {
    state = state.copyWith(
      selectedRequest: request,
      selectedDate: request.requiredOn,
      selectedTime: request.requiredAt,
      price: request.offeredPrice,
    );
  }

  void selectEquipment(EquipmentSummaryModel equipment) {
    state = state.copyWith(selectedEquipment: equipment);
  }

  List<OfferModel> getActiveOffers(String requestId, String? mode) {
    return (mode == "owner" ? state.ownerOffers : state.renterOffers)
        .where(
          (item) =>
              item.requestId == requestId &&
              ["CREATED", "VIEWED"].contains(item.status),
        )
        .toList();
  }

  bool hasActiveOffer(String requestId, String? mode) {
    final activeOffers = getActiveOffers(requestId, mode);

    return activeOffers.isNotEmpty;
  }

  void setPrice(int price) {
    state = state.copyWith(price: price);
  }

  void setPriceRate(String priceRate) {
    state = state.copyWith(priceRate: priceRate);
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setTime(DateTime time) {
    state = state.copyWith(selectedTime: time);
  }

  void setComment(String comment) {
    state = state.copyWith(comment: comment);
  }

  Future<void> getClientOffers() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.getClientOffers();

      state = state.copyWith(
        isLoading: false,
        renterOffers: result.data,
        error: result.success ? null : result.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        renterOffers: [],
        error: e.toString(),
      );
    }
  }

  Future<bool> acceptOffer(String id) async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.acceptOffer(id: id);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getClientOffers();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> rejectOffer(String id) async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.rejectOffer(id: id);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getClientOffers();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> getOwnerOffers() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.getOwnerOffers();

      state = state.copyWith(
        isLoading: false,
        ownerOffers: result.data,
        error: result.success ? null : result.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        ownerOffers: [],
        error: e.toString(),
      );
    }
  }

  Future<bool> createOffer() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.createOffer(
        price: state.price ?? 0,
        priceRate: state.priceRate.toString(),
        comment: state.comment,
        equipmentId: state.selectedEquipment?.id ?? "",
        requestId: state.selectedRequest?.id ?? "",
      );

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getOwnerOffers();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelOffer(String id) async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.cancelOffer(id: id);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getOwnerOffers();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
