import 'package:prokat/features/catalog/models/catalog_spec_type.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

String _asString(dynamic value) => value?.toString() ?? '';

List<Map<String, dynamic>> _asObjectList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    return Map<String, dynamic>.from(item);
  }).toList();
}

class CatalogCity {
  final String id;
  final String slug;
  final LocalizedNames names;
  final bool isVisible;
  final bool acceptsEquipment;
  final String? region;
  final int sortIndex;

  const CatalogCity({
    required this.id,
    required this.slug,
    required this.names,
    required this.isVisible,
    required this.acceptsEquipment,
    this.region,
    required this.sortIndex,
  });

  factory CatalogCity.fromJson(Map<String, dynamic> json) {
    return CatalogCity(
      id: _asString(json['id']),
      slug: _asString(json['slug']),
      names: LocalizedNames.fromJson(json['names']),
      isVisible: _asBool(json['isVisible'], fallback: true),
      acceptsEquipment: _asBool(json['acceptsEquipment'], fallback: true),
      region: json['region']?.toString(),
      sortIndex: _asInt(json['sortIndex']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'names': names.toJson(),
    'isVisible': isVisible,
    'acceptsEquipment': acceptsEquipment,
    'region': region,
    'sortIndex': sortIndex,
  };

  String label(String languageCode) {
    return names.pick(languageCode, fallback: slug);
  }
}

class CatalogCategory {
  final String id;
  final String slug;
  final LocalizedNames names;
  final String? imageUrl;
  final int sortIndex;
  final bool isUserVisible;
  final bool isOwnerVisible;

  const CatalogCategory({
    required this.id,
    required this.slug,
    required this.names,
    this.imageUrl,
    required this.sortIndex,
    required this.isUserVisible,
    required this.isOwnerVisible,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: _asString(json['id']),
      slug: _asString(json['slug']),
      names: LocalizedNames.fromJson(json['names']),
      imageUrl: json['imageUrl']?.toString(),
      sortIndex: _asInt(json['sortIndex']),
      isUserVisible: _asBool(json['isUserVisible'], fallback: true),
      isOwnerVisible: _asBool(json['isOwnerVisible'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'names': names.toJson(),
    'imageUrl': imageUrl,
    'sortIndex': sortIndex,
    'isUserVisible': isUserVisible,
    'isOwnerVisible': isOwnerVisible,
  };

  String label(String languageCode) {
    return names.pick(languageCode, fallback: slug);
  }
}

class CatalogUnit {
  final String id;
  final String slug;
  final LocalizedNames symbols;
  final LocalizedNames? names;
  final int sortIndex;

  const CatalogUnit({
    required this.id,
    required this.slug,
    required this.symbols,
    this.names,
    required this.sortIndex,
  });

  factory CatalogUnit.fromJson(Map<String, dynamic> json) {
    return CatalogUnit(
      id: _asString(json['id']),
      slug: _asString(json['slug']),
      symbols: LocalizedNames.fromJson(json['symbols']),
      names: json['names'] == null
          ? null
          : LocalizedNames.fromJson(json['names']),
      sortIndex: _asInt(json['sortIndex']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'symbols': symbols.toJson(),
    'names': names?.toJson(),
    'sortIndex': sortIndex,
  };

  String symbol(String languageCode) {
    return symbols.pick(languageCode, fallback: slug);
  }
}

class CatalogSpec {
  final String id;
  final String slug;
  final LocalizedNames names;
  final CatalogSpecType type;
  final String? unitId;
  final String? iconLibrary;
  final String? iconName;
  final double? minNumber;
  final double? maxNumber;
  final int? decimals;
  final int? maxLength;
  final bool isActive;

  const CatalogSpec({
    required this.id,
    required this.slug,
    required this.names,
    required this.type,
    this.unitId,
    this.iconLibrary,
    this.iconName,
    this.minNumber,
    this.maxNumber,
    this.decimals,
    this.maxLength,
    required this.isActive,
  });

  factory CatalogSpec.fromJson(Map<String, dynamic> json) {
    return CatalogSpec(
      id: _asString(json['id']),
      slug: _asString(json['slug']),
      names: LocalizedNames.fromJson(json['names']),
      type: CatalogSpecType.parse(json['type']?.toString()),
      unitId: json['unitId']?.toString(),
      iconLibrary: json['iconLibrary']?.toString(),
      iconName: json['iconName']?.toString(),
      minNumber: _asDouble(json['minNumber']),
      maxNumber: _asDouble(json['maxNumber']),
      decimals: json['decimals'] == null ? null : _asInt(json['decimals']),
      maxLength: json['maxLength'] == null ? null : _asInt(json['maxLength']),
      isActive: _asBool(json['isActive'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'names': names.toJson(),
    'type': type.wireName,
    'unitId': unitId,
    'iconLibrary': iconLibrary,
    'iconName': iconName,
    'minNumber': minNumber,
    'maxNumber': maxNumber,
    'decimals': decimals,
    'maxLength': maxLength,
    'isActive': isActive,
  };

  String label(String languageCode) {
    return names.pick(languageCode, fallback: slug);
  }
}

class CatalogSpecOption {
  final String id;
  final String specId;
  final String slug;
  final LocalizedNames names;
  final int sortIndex;
  final bool isActive;

  const CatalogSpecOption({
    required this.id,
    required this.specId,
    required this.slug,
    required this.names,
    required this.sortIndex,
    this.isActive = true,
  });

  factory CatalogSpecOption.fromJson(Map<String, dynamic> json) {
    return CatalogSpecOption(
      id: _asString(json['id']),
      specId: _asString(json['specId']),
      slug: _asString(json['slug']),
      names: LocalizedNames.fromJson(json['names']),
      sortIndex: _asInt(json['sortIndex']),
      isActive: _asBool(json['isActive'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'specId': specId,
    'slug': slug,
    'names': names.toJson(),
    'sortIndex': sortIndex,
    'isActive': isActive,
  };

  String label(String languageCode) {
    return names.pick(languageCode, fallback: slug);
  }
}

class CatalogCategorySpec {
  final String id;
  final String categoryId;
  final String specId;
  final bool isRequired;
  final bool visibleToClient;
  final bool showInFilters;
  final bool showInCard;
  final int sortIndex;

  const CatalogCategorySpec({
    required this.id,
    required this.categoryId,
    required this.specId,
    required this.isRequired,
    required this.visibleToClient,
    required this.showInFilters,
    required this.showInCard,
    required this.sortIndex,
  });

  factory CatalogCategorySpec.fromJson(Map<String, dynamic> json) {
    final visible = _asBool(json['visibleToClient'], fallback: true);
    return CatalogCategorySpec(
      id: _asString(json['id']),
      categoryId: _asString(json['categoryId']),
      specId: _asString(json['specId']),
      isRequired: _asBool(json['isRequired']),
      visibleToClient: visible,
      showInFilters: _asBool(json['showInFilters'], fallback: true) && visible,
      showInCard: _asBool(json['showInCard'], fallback: true) && visible,
      sortIndex: _asInt(json['sortIndex']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'categoryId': categoryId,
    'specId': specId,
    'isRequired': isRequired,
    'visibleToClient': visibleToClient,
    'showInFilters': showInFilters,
    'showInCard': showInCard,
    'sortIndex': sortIndex,
  };
}

class CatalogBundle {
  final String version;
  final List<CatalogCity> cities;
  final List<CatalogCategory> categories;
  final List<CatalogUnit> units;
  final List<CatalogSpec> specs;
  final List<CatalogSpecOption> specOptions;
  final List<CatalogCategorySpec> categorySpecs;

  const CatalogBundle({
    required this.version,
    required this.cities,
    required this.categories,
    required this.units,
    required this.specs,
    required this.specOptions,
    required this.categorySpecs,
  });

  factory CatalogBundle.fromJson(Map<String, dynamic> json) {
    final version = json['version']?.toString().trim() ?? '';
    if (version.isEmpty) {
      throw const FormatException('Failed to load CatalogBundle.');
    }

    return CatalogBundle(
      version: version,
      cities: _asObjectList(json['cities']).map(CatalogCity.fromJson).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)),
      categories:
          _asObjectList(
              json['categories'],
            ).map(CatalogCategory.fromJson).toList()
            ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)),
      units: _asObjectList(json['units']).map(CatalogUnit.fromJson).toList()
        ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)),
      specs: _asObjectList(json['specs']).map(CatalogSpec.fromJson).toList(),
      specOptions:
          _asObjectList(
              json['specOptions'],
            ).map(CatalogSpecOption.fromJson).toList()
            ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)),
      categorySpecs:
          _asObjectList(
              json['categorySpecs'],
            ).map(CatalogCategorySpec.fromJson).toList()
            ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex)),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'cities': cities.map((item) => item.toJson()).toList(),
    'categories': categories.map((item) => item.toJson()).toList(),
    'units': units.map((item) => item.toJson()).toList(),
    'specs': specs.map((item) => item.toJson()).toList(),
    'specOptions': specOptions.map((item) => item.toJson()).toList(),
    'categorySpecs': categorySpecs.map((item) => item.toJson()).toList(),
  };

  List<CatalogCity> get visibleCities =>
      cities.where((item) => item.isVisible).toList();

  List<CatalogCategory> get userCategories =>
      categories.where((item) => item.isUserVisible).toList();

  List<CatalogCategory> get ownerCategories =>
      categories.where((item) => item.isOwnerVisible).toList();

  CatalogCity? cityById(String? id) {
    if (id == null || id.isEmpty) return null;
    return cities.where((item) => item.id == id).firstOrNull;
  }

  CatalogCity? cityBySlugOrName(String? value) {
    final needle = value?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return null;
    return cities.where((item) {
      if (item.slug.toLowerCase() == needle) return true;
      return item.names.en.toLowerCase() == needle ||
          item.names.ru.toLowerCase() == needle ||
          item.names.kk.toLowerCase() == needle;
    }).firstOrNull;
  }

  CatalogCategory? categoryById(String? id) {
    if (id == null || id.isEmpty) return null;
    return categories.where((item) => item.id == id).firstOrNull;
  }

  CatalogSpec? specById(String? id) {
    if (id == null || id.isEmpty) return null;
    return specs.where((item) => item.id == id).firstOrNull;
  }

  CatalogSpec? specBySlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    return specs.where((item) => item.slug == slug).firstOrNull;
  }

  CatalogUnit? unitById(String? id) {
    if (id == null || id.isEmpty) return null;
    return units.where((item) => item.id == id).firstOrNull;
  }

  CatalogSpecOption? optionById(String? id) {
    if (id == null || id.isEmpty) return null;
    return specOptions.where((item) => item.id == id).firstOrNull;
  }

  List<CatalogSpecOption> optionsForSpec(String specId) {
    return specOptions
        .where((item) => item.specId == specId && item.isActive)
        .toList();
  }

  List<CatalogCategorySpec> bindingsForCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return const [];
    return categorySpecs
        .where((item) => item.categoryId == categoryId)
        .toList();
  }

  List<CatalogCategorySpec> filterBindingsForCategory(String? categoryId) {
    return bindingsForCategory(
      categoryId,
    ).where((item) => item.showInFilters && item.visibleToClient).toList();
  }
}
