class EquipmentSpecUpdateInput {
  final String specId;
  final String value;

  const EquipmentSpecUpdateInput({required this.specId, required this.value});

  Map<String, dynamic> toJson() => {'specId': specId, 'value': value};
}
