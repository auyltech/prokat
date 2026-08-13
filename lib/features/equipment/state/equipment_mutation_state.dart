import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/categories/models/category.dart';

class EquipmentMutationState {
  static const _notProvided = Object();

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
    Object? editingEquipmentId = _notProvided,
    Object? category = _notProvided,
  }) {
    assert(
      identical(editingEquipmentId, _notProvided) ||
          editingEquipmentId is String?,
      'editingEquipmentId must be a String or null',
    );
    assert(
      identical(category, _notProvided) || category is Category?,
      'category must be a Category or null',
    );

    return EquipmentMutationState(
      activeActions: activeActions ?? this.activeActions,
      editingEquipmentId: identical(editingEquipmentId, _notProvided)
          ? this.editingEquipmentId
          : editingEquipmentId as String?,
      category: identical(category, _notProvided)
          ? this.category
          : category as Category?,
    );
  }
}
