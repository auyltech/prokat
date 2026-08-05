import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';

class OffersState {
  final Set<Mutation> activeActions;

  final EquipmentSummaryModel? selectedEquipment;
  final RequestModel? selectedRequest;

  final int? price;
  final PriceRateOption? priceRate;
  final String? comment;

  final DateTime? selectedDate;
  final DateTime? selectedTime;

  OffersState({
    this.activeActions = const {},
    this.selectedRequest,
    this.selectedEquipment,

    this.price,
    this.priceRate,
    this.comment,

    this.selectedDate,
    this.selectedTime,
  });

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
    Set<Mutation>? activeActions,
    EquipmentSummaryModel? selectedEquipment,
    RequestModel? selectedRequest,
    int? price,
    PriceRateOption? priceRate,
    String? comment,

    DateTime? selectedDate,
    DateTime? selectedTime,
  }) {
    return OffersState(
      activeActions: activeActions ?? this.activeActions,
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
