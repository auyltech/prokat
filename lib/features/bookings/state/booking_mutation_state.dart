import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class BookingMutationState {
  final Set<Mutation> activeActions;

  final BookingModel? draftBooking;

  final Equipment? selectedEquipment;
  final PriceEntry? selectedPriceEntry;

  final LocationModel? selectedLocation;
  final String? selectedLocationId;

  final DateTime? selectedDate;
  final DateTime? selectedTime;

  final String? comment;

  const BookingMutationState({
    this.activeActions = const {},

    this.draftBooking,

    this.selectedEquipment,
    this.selectedPriceEntry,

    this.selectedLocation,
    this.selectedLocationId,

    this.selectedDate,
    this.selectedTime,

    this.comment,
  });

  bool get isSubmitting =>
      activeActions.any((item) => item.status == MutationStatus.submitting);

  bool isActionActive(String actionId) {
    return activeActions.any(
      (action) =>
          action.id == actionId && action.status == MutationStatus.submitting,
    );
  }

  BookingMutationState copyWith({
    Set<Mutation>? activeActions,
    BookingModel? draftBooking,
    Equipment? selectedEquipment,
    PriceEntry? selectedPriceEntry,
    LocationModel? selectedLocation,
    String? selectedLocationId,
    DateTime? selectedDate,
    DateTime? selectedTime,
    String? comment,
  }) {
    return BookingMutationState(
      activeActions: activeActions ?? this.activeActions,

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
