import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_api_service.dart';
import 'package:prokat/features/bookings/state/booking_state.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingApiService api;

  BookingNotifier(this.api) : super(BookingState());

  /// -------------------------
  /// LOCAL DRAFT MANAGEMENT
  /// -------------------------

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

  List<BookingModel> getActiveBookings({required String mode}) {
    return (mode == "owner" ? state.ownerBookings : state.bookings)
        .where(
          (b) =>
              [
                BookingStatus.created,
                BookingStatus.confirmed,
                BookingStatus.completed,
              ].contains(b.status) &&
              (b.myReviewId?.isNotEmpty == true),
        )
        .toList();
  }

  /// -------------------------
  /// LOAD BOOKINGS
  /// -------------------------

  Future<void> getUserBookings() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await api.getUserBookings();

      state = state.copyWith(
        isLoading: false,
        bookings: result.data,
        error: result.success ? null : result.message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getOwnerBookings() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await api.getOwnerBookings();

      state = state.copyWith(
        isLoading: false,
        ownerBookings: result.data,
        error: result.success ? null : result.message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// -------------------------
  /// CREATE BOOKING
  /// -------------------------

  Future<bool> createBooking() async {
    try {
      if (state.selectedEquipment == null || state.selectedLocation == null) {
        return false;
      }

      state = state.copyWith(isSubmitting: true, actionId: "booking:create");

      final result = await api.createBooking({
        "bookedOn": state.selectedDate!.toIso8601String(),
        "bookedAt": state.selectedTime!.toIso8601String(),
        "price": (int.tryParse(
          state.selectedPriceEntry?.price.toString() ?? '0',
        )).toString(),
        "priceRate": state.selectedPriceEntry?.priceRate ?? "",
        "comment": state.comment,
        "equipmentId": state.selectedEquipment?.id,
        "locationId": state.selectedLocation?.id,
      });

      state = state.copyWith(
        isSubmitting: false,
        error: result.success ? null : result.message,
        actionId: null,
      );

      if (result.success) {
        await getUserBookings();
      }

      return result.success;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: error.toString(),
        actionId: null,
      );
      return false;
    }
  }

  /// -------------------------
  /// UPDATE BOOKING
  /// -------------------------
  Future<bool> updateBookingStatus({
    required String id,
    String? status,
    String? workStatus,
  }) async {
    try {
      state = state.copyWith(isSubmitting: true, actionId: "booking:status");

      final result = await api.updateBookingStatus(
        id: id,
        status: status,
        workStatus: workStatus,
      );

      state = state.copyWith(
        isSubmitting: false,
        error: result.success ? null : result.message,
        actionId: null,
      );

      if (result.success) {
        await getUserBookings();
      }

      return result.success;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: error.toString(),
        actionId: null,
      );
      return false;
    }
  }

  Future<bool> updateBookingWorkStatus({
    required String id,
    String? status,
    String? workStatus,
  }) async {
    try {
      state = state.copyWith(
        isSubmitting: true,
        actionId: "booking:workstatus",
      );

      final result = await api.updateBookingWorkStatus(
        id: id,
        status: status,
        workStatus: workStatus,
      );

      state = state.copyWith(
        isSubmitting: false,
        error: result.success ? null : result.message,
        actionId: null,
      );

      if (result.success) {
        await getUserBookings();
      }

      return result.success;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        error: error.toString(),
        actionId: null,
      );
      return false;
    }
  }
}
