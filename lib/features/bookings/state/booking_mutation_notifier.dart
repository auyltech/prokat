import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/mutation/mutation_notifier.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/state/booking_service.dart';
import 'package:prokat/features/bookings/state/booking_mutation_state.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:riverpod/riverpod.dart';

class BookingMutationNotifier extends MutationNotifier<BookingMutationState> {
  final BookingService api;
  final Ref ref;

  BookingMutationNotifier({required this.api, required this.ref})
    : super(const BookingMutationState());

  @override
  Set<Mutation> get activeActions => state.activeActions;

  @override
  BookingMutationState copyState({Set<Mutation>? activeActions}) {
    return state.copyWith(activeActions: activeActions);
  }

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

      startAction(actionId);

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
        // Don't await, return true to show snackbar
        ref.read(clientActiveBookingsProvider.notifier).refresh();
        ref.read(clientChatsProvider.notifier).refresh();
      }

      return MutationResponse(
        success: result.success,
        message: result.success ? "Order created" : result.message,
      );
    } catch (error) {
      finishAction(
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

  Future<MutationResponse> updateBookingStatus({
    required String id,
    BookingStatus? status,
    WorkStatus? workStatus,
    String? cancelReason,
  }) async {
    final actionId = "booking:update:$id";

    try {
      startAction(actionId);

      final result = await api.updateBookingStatus(
        id: id,
        status: status,
        workStatus: workStatus,
        cancelReason: cancelReason,
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
        ref.read(clientActiveBookingsProvider.notifier).refresh();
        ref.read(ownerActiveBookingsProvider.notifier).refresh();

        // final chatNotifier = ref.read(chatProvider.notifier);

        // final booking = [
        //   ...state.clientBookings,
        //   ...state.ownerBookings,
        // ].where((item) => item.id == id).firstOrNull;

        // final chatId = booking != null && booking.chatId != null
        //     ? booking.chatId ?? ""
        //     : "";

        // if (chatId.isNotEmpty) {
        //   chatNotifier.reloadChat(chatId);
        // }
      }

      return MutationResponse(success: result.success, message: result.message);
    } catch (error) {
      finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to update booking",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to update order status",
      );
    }
  }

  Future<MutationResponse> updateBookingWorkStatus({
    required String id,
    BookingStatus? status,
    WorkStatus? workStatus,
  }) async {
    final actionId = "booking:workstatus:$id";
    try {
      startAction(actionId);

      final result = await api.updateBookingWorkStatus(
        id: id,
        status: status,
        workStatus: workStatus,
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
        ref.read(clientActiveBookingsProvider.notifier).refresh();
        ref.read(ownerActiveBookingsProvider.notifier).refresh();
      }

      return MutationResponse(success: result.success, message: result.message);
    } catch (error) {
      finishAction(
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
