import 'package:prokat/core/mutation/mutation_model.dart';

class SupportState {
  final Set<Mutation> activeActions;

  const SupportState({this.activeActions = const {}});

  bool get isSubmitting =>
      activeActions.any((item) => item.status == MutationStatus.submitting);

  bool isActionActive(String actionId) {
    return activeActions.any(
      (action) =>
          action.id == actionId && action.status == MutationStatus.submitting,
    );
  }

  SupportState copyWith({Set<Mutation>? activeActions}) {
    return SupportState(activeActions: activeActions ?? this.activeActions);
  }
}
