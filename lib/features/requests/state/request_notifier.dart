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

  Future<void> getClientRequests() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.getClientRequests();

      state = state.copyWith(
        isLoading: false,
        requests: result.data,
        error: result.success ? null : result.message,
      );
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

      final result = await service.getOwnerRequests();

      state = state.copyWith(
        isLoading: false,
        ownerRequests: result.data,
        error: result.success ? null : result.message,
      );
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
      // 1. Guard check: ensures critical fields are present
      if (state.selectedDate == null) return false;

      state = state.copyWith(isLoading: true);

      // 2. Safely merge Date and Time to avoid layout parsing bugs down the line
      final DateTime mergedDate = DateTime(
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
      );

      // If user didn't pick a time, default it to the same date day configuration
      final DateTime? mergedTime = state.selectedTime != null
          ? DateTime(
              state.selectedDate!.year,
              state.selectedDate!.month,
              state.selectedDate!.day,
              state.selectedTime!.hour,
              state.selectedTime!.minute,
            )
          : null;

      // 3. Fire the request service
      final result = await service.createRequest(
        categoryId: categoryId,
        // Fallback to a placeholder string if your backend expects a UUID pattern instead of ""
        locationId: state.selectedLocation?.id ?? "unspecified",
        capacity: capacity,
        requiredOn: mergedDate,
        requiredAt: mergedTime,
        comment: comment,
        offeredRate: offeredRate,
      );

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getClientRequests();
      }

      return result.success;
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

      final result = await service.updateRequest(
        id: id,
        locationId: locationId,
        requiredOn: requiredOn,
        requiredAt: requiredAt,
        offeredRate: offeredRate,
      );

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getClientRequests();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelRequest(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      final result = await service.cancelRequest(id);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getClientRequests();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      final result = await service.rejectRequest(id);

      state = state.copyWith(isLoading: false);

      if (result.success) {
        await getClientRequests();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
