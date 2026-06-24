import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
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

  void _startAction(String actionId) {
    state = state.copyWith(
      activeActions: {
        ...state.activeActions,
        Mutation(id: actionId, status: MutationStatus.submitting),
      },
    );
  }

  void _finishAction(String actionId, {AppError? error}) {
    final actions = {...state.activeActions};

    if (error == null) {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));
    } else {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));

      final action = Mutation(
        id: actionId,
        status: MutationStatus.error,
        error: error,
      );

      actions.add(action);
    }

    state = state.copyWith(activeActions: actions);
  }

  bool isActionActive(String actionId) {
    return state.activeActions.contains(
      Mutation(id: actionId, status: MutationStatus.submitting),
    );
  }

  List<RequestModel> getActiveRequests(AppMode mode) {
    return (mode == AppMode.ownerMode
            ? state.ownerRequests
            : state.clientRequests)
        .where(
          (r) => [
            RequestStatus.created,
            RequestStatus.viewed,
            RequestStatus.responded,
          ].contains(r.status),
        )
        .toList();
  }

  List<RequestModel> getRequestHistory(AppMode mode) {
    return (mode == AppMode.ownerMode
            ? state.ownerRequests
            : state.clientRequests)
        .where(
          (r) => [
            RequestStatus.accepted,
            RequestStatus.cancelled,
            RequestStatus.expired,
          ].contains(r.status),
        )
        .toList();
  }

  Future<void> getClientRequests() async {
    try {
      final hasData = state.clientRequests.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await service.getClientRequests();

      state = state.copyWith(
        clientRequests: result.data,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "REQUEST_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientRequests.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "BOOKING_FETCH_FAILED",
        ),
      );
    }
  }

  Future<void> getOwnerRequests() async {
    try {
      final hasData = state.ownerRequests.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await service.getOwnerRequests();

      state = state.copyWith(
        ownerRequests: result.data,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "REQUEST_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.ownerRequests.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "BOOKING_FETCH_FAILED",
        ),
      );
    }
  }

  Future<bool> createRequest({
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
        return false;
      }

      _startAction(actionId);

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
        locationId: state.selectedLocation?.id ?? "",
        capacity: capacity,
        requiredOn: mergedDate,
        requiredAt: mergedTime,
        comment: comment,
        offeredRate: offeredRate,
      );

      _finishAction(
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
        getClientRequests();
      }

      return result.success;
    } catch (e) {
      _finishAction(actionId);

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
    final actionId = "request:$id:update";

    try {
      _startAction(actionId);

      final result = await service.updateRequest(
        id: id,
        locationId: locationId,
        requiredOn: requiredOn,
        requiredAt: requiredAt,
        offeredRate: offeredRate,
      );

      _finishAction(
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
        getClientRequests();
      }

      return result.success;
    } catch (error) {
      _finishAction(actionId);
      return false;
    }
  }

  Future<bool> viewRequest(String id) async {
    final actionId = "request:$id:view";

    try {
      _startAction(actionId);

      final result = await service.viewRequest(id);

      _finishAction(
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
        getOwnerRequests();
      }

      return result.success;
    } catch (error) {
      _finishAction(actionId);
      return false;
    }
  }

  Future<bool> cancelRequest(String id) async {
    final actionId = "request:$id:cancel";

    try {
      _startAction(actionId);

      final result = await service.cancelRequest(id);

      _finishAction(
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
        getClientRequests();
      }

      return result.success;
    } catch (error) {
      _finishAction(actionId);
      return false;
    }
  }
}
