import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_notifier.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';

final ownerEquipmentEditorProvider = StateNotifierProvider.autoDispose
    .family<OwnerEquipmentEditorNotifier, OwnerEquipmentEditorState, String>(
      (ref, _) => OwnerEquipmentEditorNotifier(),
    );
