import 'package:prokat/core/mutation/mutation_model.dart';

class PriceNegotiationState {
  final Set<Mutation> activeActions;

  const PriceNegotiationState({this.activeActions = const {}});

  bool get isSubmitting =>
      activeActions.any((action) => action.status == MutationStatus.submitting);

  bool isActionActive(String actionId) {
    return activeActions.any(
      (action) =>
          action.id == actionId && action.status == MutationStatus.submitting,
    );
  }

  PriceNegotiationState copyWith({Set<Mutation>? activeActions}) {
    return PriceNegotiationState(
      activeActions: activeActions ?? this.activeActions,
    );
  }
}
