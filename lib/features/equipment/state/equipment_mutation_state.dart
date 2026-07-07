import 'package:flutter/foundation.dart';
import 'package:prokat/core/api/fetch_status.dart';

class EquipmentMutationState {
  final Set<Mutation> activeActions;

  /// Equipment currently being edited.
  final String? editingEquipmentId;

  /// Selected category while editing/creating.
  final Category? category;

  const EquipmentMutationState({
    this.activeActions = const {},
    this.editingEquipmentId,
    this.category,
  });

  bool get isSubmitting =>
      activeActions.any((action) => action.status == MutationStatus.submitting);

  bool isActionActive(String actionId) {
    return activeActions.any(
      (action) =>
          action.id == actionId && action.status == MutationStatus.submitting,
    );
  }

  EquipmentMutationState copyWith({
    Set<Mutation>? activeActions,
    String? editingEquipmentId,
    Category? category,
  }) {
    return EquipmentMutationState(
      activeActions: activeActions ?? this.activeActions,
      editingEquipmentId: editingEquipmentId,
      category: category ?? this.category,
    );
  }
}
