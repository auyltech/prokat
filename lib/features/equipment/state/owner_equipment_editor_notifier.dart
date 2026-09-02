import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/utils/equipment_submit_readiness.dart';

typedef BlockSaveHandler = Future<bool> Function({required bool notify});
typedef BlockValidateHandler = bool Function();

class _InfoDraft {
  String? name;
  String? model;
  String? plateNumber;
  String? ownerComment;
  String? rentCondition;
}

class OwnerEquipmentEditorNotifier
    extends StateNotifier<OwnerEquipmentEditorState> {
  OwnerEquipmentEditorNotifier() : super(const OwnerEquipmentEditorState());

  final Map<OwnerEquipmentBlockId, BlockSaveHandler> _savers = {};
  final Map<OwnerEquipmentBlockId, BlockValidateHandler> _validators = {};
  final Set<OwnerEquipmentBlockId> _seen = {};
  final _InfoDraft _info = _InfoDraft();

  void bind({
    required OwnerEquipmentBlockId id,
    required BlockSaveHandler save,
    required BlockValidateHandler validate,
  }) {
    _savers[id] = save;
    _validators[id] = validate;
  }

  void reportInfoDraft({
    String? name,
    String? model,
    String? plateNumber,
    String? ownerComment,
    String? rentCondition,
  }) {
    if (name != null) _info.name = name;
    if (model != null) _info.model = model;
    if (plateNumber != null) _info.plateNumber = plateNumber;
    if (ownerComment != null) _info.ownerComment = ownerComment;
    if (rentCondition != null) _info.rentCondition = rentCondition;
  }

  Map<String, dynamic> mergedInfoPayload(Equipment equipment) {
    return equipmentInfoPayload(
      equipment: equipment,
      name: _info.name,
      model: _info.model,
      plateNumber: _info.plateNumber,
      ownerComment: _info.ownerComment,
      rentCondition: _info.rentCondition,
    );
  }

  void report({
    required OwnerEquipmentBlockId id,
    required bool isDirty,
    required bool isSaving,
    required BlockIndicator indicator,
  }) {
    final prev = state.block(id);
    final isFirst = !_seen.contains(id);
    _seen.add(id);

    if (!isFirst &&
        prev.isDirty == isDirty &&
        prev.isSaving == isSaving &&
        prev.indicator == indicator) {
      return;
    }

    final expanded = isFirst
        ? indicator != BlockIndicator.valid
        : prev.isExpanded;

    state = state.copyWithBlock(
      id,
      prev.copyWith(
        isDirty: isDirty,
        isSaving: isSaving,
        indicator: indicator,
        isExpanded: expanded,
      ),
    );
  }

  void markSaved(
    OwnerEquipmentBlockId id, {
    required BlockIndicator indicator,
  }) {
    final prev = state.block(id);
    state = state.copyWithBlock(
      id,
      prev.copyWith(
        isDirty: false,
        isSaving: false,
        indicator: indicator,
        isExpanded: indicator == BlockIndicator.valid ? false : prev.isExpanded,
      ),
    );
  }

  void toggleExpanded(OwnerEquipmentBlockId id) {
    final prev = state.block(id);
    state = state.copyWithBlock(
      id,
      prev.copyWith(isExpanded: !prev.isExpanded),
    );
  }

  void expandAll() {
    var next = state;
    for (final id in OwnerEquipmentBlockId.values) {
      next = next.copyWithBlock(id, next.block(id).copyWith(isExpanded: true));
    }
    state = next;
  }

  void collapseAll() {
    var next = state;
    for (final id in OwnerEquipmentBlockId.values) {
      next = next.copyWithBlock(id, next.block(id).copyWith(isExpanded: false));
    }
    state = next;
  }

  Future<SaveAllResult> saveAll() async {
    final dirtyIds = OwnerEquipmentBlockId.values
        .where((id) => state.block(id).isDirty)
        .toList();
    if (dirtyIds.isEmpty) return SaveAllResult.success;

    var allValid = true;
    for (final id in dirtyIds) {
      final validate = _validators[id];
      if (validate == null) continue;
      if (!validate()) {
        allValid = false;
        final prev = state.block(id);
        state = state.copyWithBlock(
          id,
          prev.copyWith(indicator: BlockIndicator.invalid, isExpanded: true),
        );
      }
    }
    if (!allValid) return SaveAllResult.invalid;

    final infoIds = dirtyIds
        .where(
          (id) =>
              id == OwnerEquipmentBlockId.general ||
              id == OwnerEquipmentBlockId.registration,
        )
        .toList();
    final otherIds = dirtyIds.where((id) => !infoIds.contains(id)).toList();

    // Info + registration share PATCH /equipment/:id — run them one after
    // another with a merged payload so the second write cannot wipe the first.
    for (final id in infoIds) {
      final save = _savers[id];
      if (save == null) continue;
      final ok = await save(notify: false);
      if (!ok) return SaveAllResult.failed;
    }

    if (otherIds.isEmpty) return SaveAllResult.success;

    final results = await Future.wait(
      otherIds.map((id) async {
        final save = _savers[id];
        if (save == null) return true;
        return save(notify: false);
      }),
    );

    return results.every((ok) => ok)
        ? SaveAllResult.success
        : SaveAllResult.failed;
  }
}
