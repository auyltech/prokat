import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/mutation/mutation_notifier.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/state/request_service.dart';
import 'package:prokat/features/requests/state/request_state.dart';

class RequestMutationNotifier extends MutationNotifier<RequestState> {
  final RequestService api;
  final Ref ref;

  RequestMutationNotifier({required this.api, required this.ref})
    : super(RequestState());

  @override
  Set<Mutation> get activeActions => state.activeActions;

  @override
  RequestState copyState({Set<Mutation>? activeActions}) {
    return state.copyWith(activeActions: activeActions);
  }

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

  Future<MutationResponse> createRequest({
    required String capacity,
    required int offeredRate,
    required String categoryId,
    String? comment,
  }) async {
    const actionId = "request:create";

    try {
      // 1. Guard check: ensures critical fields are present
      if (state.selectedDate == null ||
          state.selectedLocation == null ||
          state.selectedLocation?.id == null ||
          state.selectedTime == null) {
        return MutationResponse(
          success: false,
          message: "Please provide required information",
        );
      }

      startAction(actionId);

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
      final result = await api.createRequest(
        categoryId: categoryId,
        locationId: state.selectedLocation?.id ?? "",
        capacity: capacity,
        requiredOn: mergedDate,
        requiredAt: mergedTime,
        comment: comment,
        offeredRate: offeredRate,
      );

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: result.error ?? "",
                message: result.message,
              ),
      );

      if (result.success) {
        ref.read(clientActiveRequestsProvider.notifier).refresh();
      }

      return MutationResponse(
        success: result.success,
        message: result.success ? "Request created" : result.message,
      );
    } catch (error) {
      finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to create request",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to create request",
      );
    }
  }

  Future<bool> updateRequest({
    required String id,
    String? locationId,
    DateTime? requiredOn,
    DateTime? requiredAt,
    int? offeredRate,
  }) async {
    final actionId = "request:$id:update";

    try {
      startAction(actionId);

      final result = await api.updateRequest(
        id: id,
        locationId: locationId,
        requiredOn: requiredOn,
        requiredAt: requiredAt,
        offeredRate: offeredRate,
      );

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        ref.read(clientActiveRequestsProvider.notifier).refresh();
      }

      return result.success;
    } catch (error) {
      finishAction(actionId);
      return false;
    }
  }

  Future<bool> viewRequest(String id) async {
    final actionId = "request:$id:view";

    try {
      startAction(actionId);

      final result = await api.viewRequest(id);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        ref.read(ownerActiveRequestsProvider.notifier).refresh();
      }

      return result.success;
    } catch (error) {
      finishAction(actionId);
      return false;
    }
  }

  Future<MutationResponse> cancelRequest(String id) async {
    final actionId = "request:$id:cancel";

    try {
      startAction(actionId);

      final result = await api.cancelRequest(id);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        ref.read(clientActiveRequestsProvider.notifier).refresh();
      }

      return MutationResponse(success: result.success, message: result.message);
    } catch (error) {
      finishAction(actionId);

      return MutationResponse(
        success: false,
        message: "Failed to cancel request",
      );
    }
  }
}
