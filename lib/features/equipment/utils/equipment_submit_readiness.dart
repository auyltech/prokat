import 'package:prokat/features/equipment/models/equipment_model.dart';

bool hasEquipmentText(String? value) => value?.trim().isNotEmpty == true;

bool equipmentHasImage(Equipment equipment) {
  return equipment.images.any((image) => hasEquipmentText(image.imageUrl)) ||
      hasEquipmentText(equipment.imageUrl);
}

bool equipmentHasIdentity(Equipment equipment) {
  return (hasEquipmentText(equipment.categoryId) ||
          hasEquipmentText(equipment.category?.id)) &&
      hasEquipmentText(equipment.name) &&
      hasEquipmentText(equipment.model) &&
      hasEquipmentText(equipment.plateNumber);
}

bool equipmentHasPrice(Equipment equipment) {
  return equipment.prices.any((entry) => entry.price > 0);
}

bool equipmentHasCity(Equipment equipment) {
  return hasEquipmentText(equipment.city) ||
      hasEquipmentText(equipment.location?.city);
}

bool equipmentHasRequiredSpecs(Equipment equipment) {
  return equipment.specs
          ?.where((spec) => spec.isRequired == true)
          .every((spec) => spec.hasFilledValue) ??
      true;
}

bool isEquipmentReadyForReview(Equipment equipment) {
  return equipmentHasImage(equipment) &&
      equipmentHasIdentity(equipment) &&
      equipmentHasPrice(equipment) &&
      equipmentHasCity(equipment) &&
      equipmentHasRequiredSpecs(equipment);
}

Map<String, dynamic> equipmentInfoPayload({
  required Equipment equipment,
  String? name,
  String? model,
  String? plateNumber,
  String? ownerComment,
  String? rentCondition,
}) {
  return {
    'id': equipment.id,
    'name': name ?? equipment.name,
    'model': model ?? equipment.model,
    'plateNumber': plateNumber ?? equipment.plateNumber,
    'ownerComment': ownerComment ?? equipment.ownerComment,
    'rentCondition': rentCondition ?? equipment.rentCondition,
  };
}
