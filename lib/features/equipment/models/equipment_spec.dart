import 'package:prokat/core/utils/parse.dart';

class EquipmentSpec {
  final String id;
  final String name;
  final String key;
  final String unit;
  final String? value;
  final String? iconLibrary;
  final String? iconName;
  final String categoryId;
  final String? inputType;
  final bool? isRequired;
  final int? sortIndex;
  final String? imageUrl;

  const EquipmentSpec({
    required this.id,
    required this.name,
    required this.key,
    required this.unit,
    this.value,
    this.iconLibrary,
    this.iconName,
    required this.categoryId,
    this.inputType,
    this.isRequired,
    this.sortIndex,
    this.imageUrl,
  });

  factory EquipmentSpec.fromJson(Map<String, dynamic> json) {
    try {
      return EquipmentSpec(
        id: json["id"] ?? "",
        name: json["name"] ?? "",
        unit: json["unit"] ?? "",
        key: json["key"] ?? "",
        value: json["value"] ?? "",
        iconLibrary: json["iconLibrary"] ?? "",
        iconName: json["iconName"] ?? "",
        categoryId: json["categoryId"] ?? "",
        inputType: json["inputType"] ?? "",
        isRequired: parseBoolean(json["isRequired"]),
        sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
        imageUrl: json["imageUrl"] ?? "",
      );
    } catch (e) {
      print("***** EQUIPMENT SPEC PARSE FAILED");
      print(e);
      print(json);
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "key": key,
      "unit": unit,
      "value": value,
      "iconName": iconName,
      "iconLibrary": iconLibrary,
      "categoryId": categoryId,
      "inputType": inputType,
      "isRequired": isRequired,
      "sortIndex": sortIndex,
      "imageUrl": imageUrl,
    };
  }
}
