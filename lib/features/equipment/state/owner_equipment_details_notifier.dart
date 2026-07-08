import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';
import 'package:riverpod/riverpod.dart';

class OwnerEquipmentDetailsNotifier
    extends FamilyAsyncNotifier<Equipment, String> {
  @override
  Future<Equipment> build(String id) async {
    final api = ref.read(equipmentServiceProvider);

    final result = await api.getOwnerEquipmentById(id);

    if (!result.success || result.data == null) {
      throw Exception(result.message);
    }

    return result.data!;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
