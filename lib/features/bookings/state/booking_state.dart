import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingState {
  final bool isLoading;
  final bool isSubmitting;
  final String? actionId;

  final String? error;

  final List<BookingModel> bookings;
  final List<BookingModel> ownerBookings;

  /// Renter draft booking
  final BookingModel? currentBooking;

  /// Renter local selections (before API create)
  final Equipment? selectedEquipment;
  final PriceEntry? selectedPriceEntry;
  final LocationModel? selectedLocation;
  final String? selectedLocationId;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final String? comment;

  BookingState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.actionId,
    this.error,
    this.bookings = const [],
    this.ownerBookings = const [],
    this.currentBooking,
    this.selectedEquipment,
    this.selectedLocation,
    this.selectedLocationId,
    this.selectedPriceEntry,
    this.selectedDate,
    this.selectedTime,
    this.comment,
  });

  BookingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? actionId,
    String? error,
    List<BookingModel>? bookings,
    List<BookingModel>? ownerBookings,
    BookingModel? currentBooking,
    Equipment? selectedEquipment,
    String? selectedLocationId,
    LocationModel? selectedLocation,
    PriceEntry? selectedPriceEntry,
    DateTime? selectedDate,
    DateTime? selectedTime,
    String? comment,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionId: actionId,
      error: error, // ?? this.error
      bookings: bookings ?? this.bookings,
      ownerBookings: ownerBookings ?? this.ownerBookings,
      currentBooking: currentBooking ?? this.currentBooking,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedPriceEntry: selectedPriceEntry ?? this.selectedPriceEntry,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      comment: comment ?? this.comment,
    );
  }
}
