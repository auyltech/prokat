class EquipmentSpecUpdateInput {
  final String specId;
  final String categorySpecId;
  final String value;

  const EquipmentSpecUpdateInput({
    required this.specId,
    required this.value,
    required this.categorySpecId,
  });

  Map<String, dynamic> toJson() => {
    'specId': specId,
    'value': value,
    "categorySpecId": categorySpecId,
  };
}
