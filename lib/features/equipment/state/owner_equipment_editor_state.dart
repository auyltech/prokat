enum OwnerEquipmentBlockId { general, registration, specs }

enum BlockIndicator { empty, valid, invalid }

enum SaveAllResult { success, invalid, failed }

class BlockEditorView {
  final bool isDirty;
  final bool isSaving;
  final bool isExpanded;
  final BlockIndicator indicator;

  const BlockEditorView({
    this.isDirty = false,
    this.isSaving = false,
    this.isExpanded = true,
    this.indicator = BlockIndicator.empty,
  });

  BlockEditorView copyWith({
    bool? isDirty,
    bool? isSaving,
    bool? isExpanded,
    BlockIndicator? indicator,
  }) {
    return BlockEditorView(
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      isExpanded: isExpanded ?? this.isExpanded,
      indicator: indicator ?? this.indicator,
    );
  }
}

class OwnerEquipmentEditorState {
  final Map<OwnerEquipmentBlockId, BlockEditorView> blocks;

  const OwnerEquipmentEditorState({this.blocks = const {}});

  BlockEditorView block(OwnerEquipmentBlockId id) =>
      blocks[id] ?? const BlockEditorView();

  bool get anyDirty =>
      OwnerEquipmentBlockId.values.any((id) => block(id).isDirty);

  bool get anySaving =>
      OwnerEquipmentBlockId.values.any((id) => block(id).isSaving);

  OwnerEquipmentEditorState copyWithBlock(
    OwnerEquipmentBlockId id,
    BlockEditorView view,
  ) {
    return OwnerEquipmentEditorState(blocks: {...blocks, id: view});
  }
}

BlockIndicator blockIndicatorFor({
  required bool complete,
  required bool saveAttempted,
}) {
  if (complete) return BlockIndicator.valid;
  if (saveAttempted) return BlockIndicator.invalid;
  return BlockIndicator.empty;
}
