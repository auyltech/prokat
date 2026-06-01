import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/offers/services/offers_service.dart';
import 'package:prokat/features/offers/state/offers_state.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class OffersNotifier extends StateNotifier<OffersState> {
  final OffersService service;

  OffersNotifier(this.service) : super(OffersState()) {
    getUserOffers();
  }

  void selectRequest(RequestModel request) {
    state = state.copyWith(
      selectedRequest: request,
      selectedDate: request.requiredOn,
      selectedTime: request.requiredAt,
      price: request.offeredPrice,
    );
  }

  void selectEquipment(Equipment equipment) {
    state = state.copyWith(selectedEquipment: equipment);
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

  Future<void> getUserOffers() async {
    try {
      state = state.copyWith(isLoading: true);

      final data = await service.getUserOffers();

      state = state.copyWith(isLoading: false, renterOffers: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        renterOffers: [],
        error: e.toString(),
      );
    }
  }

  Future<void> getOwnerOffers() async {
    try {
      state = state.copyWith(isLoading: true);

      final data = await service.getOwnerOffers();

      state = state.copyWith(isLoading: false, ownerOffers: data);
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

      final created = await service.createOffer(
        price: state.price ?? 0,
        priceRate: state.priceRate.toString(),
        comment: state.comment,
        equipmentId: state.selectedEquipment?.id ?? "",
        requestId: state.selectedRequest?.id ?? "",
      );

      if (created != null) {
        state = state.copyWith(isLoading: false);

        await getOwnerOffers();

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateOffer(String id) async {
    try {
      state = state.copyWith(isLoading: true);

      final created = await service.updateOffer(
        id: id,
        price: state.price ?? 0,
        priceRate: state.priceRate.toString(),
        comment: state.comment,
        equipmentId: state.selectedEquipment?.id ?? "",
      );

      if (created != null) {
        state = state.copyWith(
          isLoading: false,
          renterOffers: [...state.renterOffers, created],
        );

        state = state.copyWith(
          renterOffers: state.renterOffers.map((o) {
            if (o.id == id) {
              return created;
            }
            return o;
          }).toList(),
        );

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateOfferStatus(String id, String status) async {
    try {
      state = state.copyWith(isLoading: true);

      final created = await service.updateOfferStatus(id: id, status: status);

      if (created != null) {
        state = state.copyWith(
          renterOffers: state.renterOffers.map((o) {
            if (o.id == id) {
              return created;
            }
            return o;
          }).toList(),
        );

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> acceptOffer(String id) async {
    try {
      state = state.copyWith(isLoading: true);

      await service.acceptOffer(id: id);

      state = state.copyWith(isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
