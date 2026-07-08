import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class OffersState {
  final FetchStatus fetchStatus;
  final PaginationStatus paginationStatus;

  final DateTime? lastFetchedAt;
  final AppError? fetchError;

  final Set<Mutation> activeActions;

  // Offers received for client
  final List<OfferModel> clientOffers;
  final List<OfferModel> ownerOffers;

  final EquipmentSummaryModel? selectedEquipment;
  final RequestModel? selectedRequest;

  final int? price;
  final PriceRateOption? priceRate;
  final String? comment;

  final DateTime? selectedDate;
  final DateTime? selectedTime;

  OffersState({
    this.fetchStatus = FetchStatus.initial,
    this.paginationStatus = PaginationStatus.idle,
    this.lastFetchedAt,
    this.fetchError,
    this.activeActions = const {},

    this.selectedRequest,
    this.selectedEquipment,
    this.clientOffers = const [],
    this.ownerOffers = const [],

    this.price,
    this.priceRate,
    this.comment,

    this.selectedDate,
    this.selectedTime,
  });

  bool get isFetching {
    return [FetchStatus.loading, FetchStatus.refreshing].contains(fetchStatus);
  }

  bool get isSubmitting {
    return activeActions
        .where((item) => item.status == MutationStatus.submitting)
        .isNotEmpty;
  }

  bool isActionActive(String actionId) {
    return activeActions
            .where(
              (item) =>
                  item.id == actionId &&
                  item.status == MutationStatus.submitting,
            )
            .firstOrNull !=
        null;
  }

  OffersState copyWith({
    FetchStatus? fetchStatus,
    PaginationStatus? paginationStatus,
    DateTime? lastFetchedAt,
    AppError? fetchError,
    Set<Mutation>? activeActions,

    List<OfferModel>? clientOffers,
    List<OfferModel>? ownerOffers,

    EquipmentSummaryModel? selectedEquipment,
    RequestModel? selectedRequest,
    int? price,
    PriceRateOption? priceRate,
    String? comment,

    DateTime? selectedDate,
    DateTime? selectedTime,
  }) {
    return OffersState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchError: fetchError,
      activeActions: activeActions ?? this.activeActions,

      clientOffers: clientOffers ?? this.clientOffers,
      ownerOffers: ownerOffers ?? this.ownerOffers,

      selectedRequest: selectedRequest ?? this.selectedRequest,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      price: price ?? this.price,
      priceRate: priceRate ?? this.priceRate,
      comment: comment ?? this.comment,

      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
    );
  }
}
