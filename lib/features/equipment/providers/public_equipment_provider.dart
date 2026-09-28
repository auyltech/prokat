import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';

class PublicEquipmentException implements Exception {
  final int? statusCode;

  const PublicEquipmentException({this.statusCode});
}

final publicEquipmentProvider = FutureProvider.family<Equipment, String>((
  ref,
  id,
) async {
  final result = await ref
      .watch(equipmentServiceProvider)
      .getPublicEquipmentById(id);
  final equipment = result.data;
  if (!result.success || equipment == null) {
    throw PublicEquipmentException(statusCode: result.statusCode);
  }
  return equipment;
});
