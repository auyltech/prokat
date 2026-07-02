import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:prokat/features/bookings/state/booking_state.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingService api;
  final Ref ref;

  BookingNotifier({required this.api, required this.ref})
    : super(BookingState());

  void selectEquipment(Equipment equipment) {
    state = state.copyWith(selectedEquipment: equipment);
  }

  void selectPriceEntry(PriceEntry priceEntry) {
    state = state.copyWith(selectedPriceEntry: priceEntry);
  }

  void selectLocation(LocationModel location) {
    state = state.copyWith(
      selectedLocationId: location.id,
      selectedLocation: location,
    );
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

  void invalidate({required AppMode mode}) {
    state = state.copyWith(fetchStatus: FetchStatus.stale);
  }

  List<BookingModel> getActiveBookings({required AppMode mode}) {
    return (mode == AppMode.ownerMode
            ? state.ownerBookings
            : state.clientBookings)
        .where(
          (b) => [
            BookingStatus.created,
            BookingStatus.confirmed,
          ].contains(b.status),
        )
        .toList();
  }

  List<BookingModel> getHistoryBookings({required AppMode mode}) {
    return (mode == AppMode.ownerMode
            ? state.ownerBookings
            : state.clientBookings)
        .where(
          (b) => [
            BookingStatus.cancelled,
            BookingStatus.rejected,
            BookingStatus.completed,
          ].contains(b.status),
        )
        .toList();
  }

  Future<void> getClientBookings() async {
    try {
      final hasData = state.clientBookings.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getClientBookings();

      state = state.copyWith(
        clientBookings: result.data,
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
                code: "BOOKING_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientBookings.isEmpty
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

  Future<void> getOwnerBookings() async {
    try {
      final hasData = state.clientBookings.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );
      print("fetching");
      final result = await api.getOwnerBookings();

      state = state.copyWith(
        ownerBookings: result.data,
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
                code: "BOOKING_FETCH_FAILED",
              ),
      );

      print("done");
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientBookings.isEmpty
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

  Future<MutationResponse> createBooking() async {
    const actionId = "booking:create";

    try {
      if (state.selectedEquipment == null ||
          state.selectedLocation == null ||
          state.selectedPriceEntry == null ||
          state.selectedDate == null ||
          state.selectedTime == null) {
        return MutationResponse(
          success: false,
          message: "Please provide required information",
        );
      }

      _startAction(actionId);

      final result = await api.createBooking({
        "equipmentId": state.selectedEquipment?.id,
        "price": int.tryParse(
          (state.selectedPriceEntry?.price ?? 0).toString(),
        ).toString(),
        "priceRate": state.selectedPriceEntry?.priceRate.value ?? "",
        "locationId": state.selectedLocation?.id,
        "bookedOn": state.selectedDate!.toIso8601String(),
        "bookedAt": state.selectedTime!.toIso8601String(),
        "comment": state.comment,
      });

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
        // Don't await, return true to show snackbar
        getClientBookings();
        ref.read(chatProvider.notifier).getChatThreads(AppMode.clientMode);
      }

      return MutationResponse(
        success: result.success,
        message: result.success ? "Order created" : result.message,
      );
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to create order",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to create order",
      );
    }
  }

  Future<bool> updateBookingStatus({
    required String id,
    BookingStatus? status,
    WorkStatus? workStatus,
    String? cancelReason,
  }) async {
    final actionId = "booking:update:$id";

    try {
      _startAction(actionId);

      final result = await api.updateBookingStatus(
        id: id,
        status: status,
        workStatus: workStatus,
        cancelReason: cancelReason,
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
        getClientBookings();
        getOwnerBookings();

        final chatNotifier = ref.read(chatProvider.notifier);

        final booking = [
          ...state.clientBookings,
          ...state.ownerBookings,
        ].where((item) => item.id == id).firstOrNull;

        final chatId = booking != null && booking.chatId != null
            ? booking.chatId ?? ""
            : "";

        if (chatId.isNotEmpty) {
          chatNotifier.reloadChat(chatId);
        }
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to update booking",
          code: "",
        ),
      );
      return false;
    }
  }

  Future<MutationResponse> updateBookingWorkStatus({
    required String id,
    BookingStatus? status,
    WorkStatus? workStatus,
  }) async {
    final actionId = "booking:workstatus:$id";
    try {
      _startAction(actionId);

      final result = await api.updateBookingWorkStatus(
        id: id,
        status: status,
        workStatus: workStatus,
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
        getClientBookings();
        getOwnerBookings();
      }

      return MutationResponse(success: result.success, message: result.message);
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to update order status",
          code: "",
        ),
      );
      return MutationResponse(
        success: false,
        message: "Failed to update order status",
      );
    }
  }
}
