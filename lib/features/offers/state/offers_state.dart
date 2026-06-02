import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class OffersState {
  final bool isLoading;
  final String? error;

  // Offers received for renter
  final List<OfferModel> renterOffers;
  final List<OfferModel> ownerOffers;

  final EquipmentSummaryModel? selectedEquipment;
  final RequestModel? selectedRequest;

  final int? price;
  final String? priceRate;
  final String? comment;

  final DateTime? selectedDate;
  final DateTime? selectedTime;

  OffersState({
    this.isLoading = false,
    this.error,

    this.selectedRequest,
    this.selectedEquipment,
    this.renterOffers = const [],
    this.ownerOffers = const [],

    this.price,
    this.priceRate,
    this.comment,

    this.selectedDate,
    this.selectedTime,
  });

  OffersState copyWith({
    bool? isLoading,
    String? error,

    List<OfferModel>? renterOffers,
    List<OfferModel>? ownerOffers,

    EquipmentSummaryModel? selectedEquipment,
    RequestModel? selectedRequest,
    int? price,
    String? priceRate,
    String? comment,

    DateTime? selectedDate,
    DateTime? selectedTime,
  }) {
    return OffersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,

      selectedRequest: selectedRequest ?? this.selectedRequest,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      renterOffers: renterOffers ?? this.renterOffers,
      ownerOffers: ownerOffers ?? this.ownerOffers,

      price: price ?? this.price,
      priceRate: priceRate ?? this.priceRate,
      comment: comment ?? this.comment,

      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
    );
  }
}
