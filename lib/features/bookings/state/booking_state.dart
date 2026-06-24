import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingState {
  final FetchStatus fetchStatus;
  final PaginationStatus paginationStatus;

  final DateTime? lastFetchedAt;
  final AppError? fetchError;

  final Set<Mutation> activeActions;

  // Data
  final List<BookingModel> bookings;
  final List<BookingModel> ownerBookings;

  /// Renter draft booking
  final BookingModel? draftBooking;

  /// Renter local selections (before API create)
  final Equipment? selectedEquipment;
  final PriceEntry? selectedPriceEntry;
  final LocationModel? selectedLocation;
  final String? selectedLocationId;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final String? comment;

  const BookingState({
    this.fetchStatus = FetchStatus.initial,
    this.paginationStatus = PaginationStatus.idle,
    this.lastFetchedAt,
    this.fetchError,
    this.activeActions = const {},
    this.bookings = const [],
    this.ownerBookings = const [],
    this.draftBooking,
    this.selectedEquipment,
    this.selectedPriceEntry,
    this.selectedLocation,
    this.selectedLocationId,
    this.selectedDate,
    this.selectedTime,
    this.comment,
  });

  BookingState copyWith({
    FetchStatus? fetchStatus,
    PaginationStatus? paginationStatus,
    DateTime? lastFetchedAt,
    AppError? fetchError,
    Set<Mutation>? activeActions,
    List<BookingModel>? bookings,
    List<BookingModel>? ownerBookings,
    BookingModel? draftBooking,
    Equipment? selectedEquipment,
    PriceEntry? selectedPriceEntry,
    LocationModel? selectedLocation,
    String? selectedLocationId,
    DateTime? selectedDate,
    DateTime? selectedTime,
    String? comment,
  }) {
    return BookingState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchError: fetchError,
      activeActions: activeActions ?? this.activeActions,
      bookings: bookings ?? this.bookings,
      ownerBookings: ownerBookings ?? this.ownerBookings,
      draftBooking: draftBooking ?? this.draftBooking,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      selectedPriceEntry: selectedPriceEntry ?? this.selectedPriceEntry,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      comment: comment ?? this.comment,
    );
  }
}
