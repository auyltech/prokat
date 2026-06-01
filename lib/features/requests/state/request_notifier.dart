import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/requests/state/request_state.dart';

class RequestNotifier extends StateNotifier<RequestState> {
  final RequestService service;

  RequestNotifier(this.service) : super(RequestState());

  void selectLocation(LocationModel location) {
    state = state.copyWith(
      selectedLocationId: location.id,
      selectedLocation: location,
    );
  }

  void selectCategory(Category category) {
    state = state.copyWith(categoryId: category.id, selectedCategory: category);
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

  void setOfferedRate(int? offeredRate) {
    state = state.copyWith(offeredRate: offeredRate);
  }

  void setCapacity(String? capacity) {
    state = state.copyWith(capacity: capacity);
  }

  Future<void> getUserRequests() async {
    try {
      state = state.copyWith(isLoading: true);

      final data = await service.getUserRequests();

      state = state.copyWith(isLoading: false, requests: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        requests: [],
        error: e.toString(),
      );
    }
  }

  Future<void> getOwnerRequests() async {
    try {
      state = state.copyWith(isLoading: true);

      final data = await service.getOwnerRequests();

      state = state.copyWith(isLoading: false, ownerRequests: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        requests: [],
        error: e.toString(),
      );
    }
  }

  Future<bool> createRequest({
    required String capacity,
    required int offeredRate,
    required String categoryId,
    String? comment,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final created = await service.createRequest(
        categoryId: categoryId,
        locationId: state.selectedLocation?.id ?? "",
        capacity: capacity,
        requiredOn: state.selectedDate ?? DateTime(2026),
        requiredAt: state.selectedTime,
        comment: comment,
        offeredRate: offeredRate,
      );

      if (created == true) {
        state = state.copyWith(isLoading: false);

        await getUserRequests();

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        requests: state.requests,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateRequest({
    required String id,
    String? locationId,
    DateTime? requiredOn,
    DateTime? requiredAt,
    int? offeredRate,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final updated = await service.updateRequest(
        id: id,
        locationId: locationId,
        requiredOn: requiredOn,
        requiredAt: requiredAt,
        offeredRate: offeredRate,
      );

      if (updated != null) {
        await getUserRequests();

        return true;
      }

      state = state.copyWith(isLoading: false);

      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelRequest(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      final res = await service.cancelRequest(id);

      if (res == true) {
        await getUserRequests();
      }

      state = state.copyWith(isLoading: false);

      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      final res = await service.rejectRequest(id);

      if (res == true) {
        await getOwnerRequests();
      }

      state = state.copyWith(isLoading: false);

      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
