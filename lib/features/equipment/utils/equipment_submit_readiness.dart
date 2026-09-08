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

/// Stable snapshot of owner-editable fields used to detect a rejected resubmit.
String equipmentReviewFingerprint(Equipment equipment) {
  final images = <String>[
    ...equipment.images.map((image) => image.imageUrl.trim()),
    if (hasEquipmentText(equipment.imageUrl)) equipment.imageUrl!.trim(),
  ];
  final prices = equipment.prices
      .map((entry) => '${entry.id}:${entry.price}:${entry.priceRate.value}')
      .join(',');
  final specs = (equipment.specs ?? [])
      .map(
        (spec) =>
            '${spec.id}:${spec.numberValue ?? ''}:${spec.boolValue ?? ''}:'
            '${spec.textValue ?? ''}:${spec.optionIds.join('+')}',
      )
      .join(',');
  return [
    equipment.name.trim(),
    equipment.model.trim(),
    (equipment.plateNumber ?? '').trim(),
    (equipment.ownerComment ?? '').trim(),
    (equipment.rentCondition ?? '').trim(),
    (equipment.city ?? '').trim(),
    images.join('|'),
    prices,
    specs,
  ].join('\u001f');
}

class OwnerEquipmentReviewUi {
  final bool showSaveAll;
  final bool showSubmitForReview;
  final bool showResubmit;

  const OwnerEquipmentReviewUi({
    required this.showSaveAll,
    required this.showSubmitForReview,
    required this.showResubmit,
  });

  factory OwnerEquipmentReviewUi.from({
    required EquipmentStatus status,
    required bool anyDirty,
  }) {
    if (status == EquipmentStatus.draft) {
      return OwnerEquipmentReviewUi(
        showSaveAll: anyDirty,
        showSubmitForReview: !anyDirty,
        showResubmit: false,
      );
    }
    if (status == EquipmentStatus.rejected) {
      return const OwnerEquipmentReviewUi(
        showSaveAll: false,
        showSubmitForReview: false,
        showResubmit: true,
      );
    }
    if (status == EquipmentStatus.created) {
      return const OwnerEquipmentReviewUi(
        showSaveAll: false,
        showSubmitForReview: false,
        showResubmit: false,
      );
    }
    return OwnerEquipmentReviewUi(
      showSaveAll: anyDirty,
      showSubmitForReview: false,
      showResubmit: false,
    );
  }
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
