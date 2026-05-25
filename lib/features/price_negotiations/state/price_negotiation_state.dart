import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';

class PriceNegotiationState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<PriceNegotiation> negotiations;

  const PriceNegotiationState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.negotiations = const [],
  });

  PriceNegotiation? get latestPending {
    for (final n in negotiations) {
      if (n.status == PriceNegotiationStatus.pending) return n;
    }

    return null;
  }

  PriceNegotiation? get latestAccepted {
    for (final n in negotiations) {
      if (n.status == PriceNegotiationStatus.accepted) return n;
    }
    return null;
  }

  PriceNegotiationState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    List<PriceNegotiation>? negotiations,
  }) {
    return PriceNegotiationState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      negotiations: negotiations ?? this.negotiations,
    );
  }
}
