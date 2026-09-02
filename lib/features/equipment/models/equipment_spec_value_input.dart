class EquipmentSpecValueInput {
  final String specId;
  final double? numberValue;
  final bool? boolValue;
  final String? textValue;
  final List<String> optionIds;

  const EquipmentSpecValueInput({
    required this.specId,
    this.numberValue,
    this.boolValue,
    this.textValue,
    this.optionIds = const [],
  });

  Map<String, dynamic> toJson() => {
    'specId': specId,
    'numberValue': numberValue,
    'boolValue': boolValue,
    'textValue': textValue,
    'optionIds': optionIds,
  };
}
