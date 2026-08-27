import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_spec_type.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';

class EquipmentSpec {
  final String id;
  final String? specId;
  final String name;
  final LocalizedNames names;
  final String key;
  final String unit;
  final String? value;
  final double? numberValue;
  final bool? boolValue;
  final String? textValue;
  final List<String> optionIds;
  final String? iconLibrary;
  final String? iconName;
  final String categoryId;
  final String? inputType;
  final String? type;
  final bool? isRequired;
  final bool? visibleToClient;
  final bool? showInCard;
  final bool? showInFilters;
  final int? sortIndex;
  final String? imageUrl;

  const EquipmentSpec({
    required this.id,
    this.specId,
    required this.name,
    this.names = const LocalizedNames(),
    required this.key,
    required this.unit,
    this.value,
    this.numberValue,
    this.boolValue,
    this.textValue,
    this.optionIds = const [],
    this.iconLibrary,
    this.iconName,
    required this.categoryId,
    this.inputType,
    this.type,
    this.isRequired,
    this.visibleToClient,
    this.showInCard,
    this.showInFilters,
    this.sortIndex,
    this.imageUrl,
  });

  factory EquipmentSpec.fromJson(Map<String, dynamic> json) {
    final names = LocalizedNames.fromJson(json['names']);
    final optionIds = <String>[];
    final rawOptions = json['optionIds'] ?? json['selectedOptions'];
    if (rawOptions is List) {
      for (final item in rawOptions) {
        final id = item?.toString();
        if (id != null && id.isNotEmpty) optionIds.add(id);
      }
    }

    final name = json['name']?.toString() ?? '';
    return EquipmentSpec(
      id: json['id'] ?? json['equipmentSpecId'] ?? '',
      specId: json['specId']?.toString(),
      name: name.isNotEmpty ? name : names.pick('en'),
      names: names,
      unit: json['unit'] ?? '',
      key: json['key'] ?? '',
      value: json['value']?.toString(),
      numberValue: json['numberValue'] is num
          ? (json['numberValue'] as num).toDouble()
          : double.tryParse(json['numberValue']?.toString() ?? ''),
      boolValue: json['boolValue'] is bool ? json['boolValue'] as bool : null,
      textValue: json['textValue']?.toString(),
      optionIds: optionIds,
      iconLibrary: json['iconLibrary'] ?? '',
      iconName: json['iconName'] ?? '',
      categoryId: json['categoryId'] ?? '',
      inputType: json['inputType']?.toString() ?? json['type']?.toString(),
      type: json['type']?.toString() ?? json['inputType']?.toString(),
      isRequired: parseBoolean(json['isRequired']),
      visibleToClient: json['visibleToClient'] == null
          ? null
          : parseBoolean(json['visibleToClient']),
      showInCard: json['showInCard'] == null
          ? null
          : parseBoolean(json['showInCard']),
      showInFilters: json['showInFilters'] == null
          ? null
          : parseBoolean(json['showInFilters']),
      sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'specId': specId,
      'name': name,
      'names': names.toJson(),
      'key': key,
      'unit': unit,
      'value': value,
      'numberValue': numberValue,
      'boolValue': boolValue,
      'textValue': textValue,
      'optionIds': optionIds,
      'iconName': iconName,
      'iconLibrary': iconLibrary,
      'categoryId': categoryId,
      'inputType': inputType,
      'type': type,
      'isRequired': isRequired,
      'visibleToClient': visibleToClient,
      'showInCard': showInCard,
      'showInFilters': showInFilters,
      'sortIndex': sortIndex,
      'imageUrl': imageUrl,
    };
  }

  CatalogSpecType resolvedType([CatalogSpec? catalogSpec]) {
    return catalogSpec?.type ?? CatalogSpecType.parse(type ?? inputType);
  }

  String displayName(String languageCode) {
    return names.pick(languageCode, fallback: name.isNotEmpty ? name : key);
  }

  String displayValue({
    required String languageCode,
    CatalogBundle? catalog,
  }) {
    if (optionIds.isNotEmpty && catalog != null) {
      final labels = optionIds
          .map((id) => catalog.optionById(id)?.label(languageCode) ?? id)
          .where((item) => item.isNotEmpty)
          .toList();
      if (labels.isNotEmpty) return labels.join(', ');
    }
    if (numberValue != null) {
      final number = numberValue!;
      final formatted = number == number.roundToDouble()
          ? number.toInt().toString()
          : number.toString();
      return unit.trim().isEmpty ? formatted : '$formatted $unit';
    }
    if (boolValue != null) return boolValue! ? 'true' : 'false';
    if (textValue != null && textValue!.trim().isNotEmpty) {
      return textValue!.trim();
    }
    return (value ?? '').trim();
  }
}
