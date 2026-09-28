import 'package:prokat/features/equipment/models/equipment_model.dart';

bool isShareableNow(Equipment equipment) {
  return equipment.status == EquipmentStatus.available &&
      equipment.isVisible &&
      equipment.prices.any((entry) => entry.price > 0);
}

bool canShowShareButton(Equipment equipment) => equipment.isModerated;

bool needsPublishAlert(Equipment equipment) {
  return canShowShareButton(equipment) && !isShareableNow(equipment);
}
