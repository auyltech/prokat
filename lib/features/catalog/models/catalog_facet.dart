import 'package:prokat/features/catalog/models/catalog_spec_type.dart';

class CatalogFacetOption {
  final String optionId;
  final String slug;
  final int count;

  const CatalogFacetOption({
    required this.optionId,
    required this.slug,
    required this.count,
  });

  factory CatalogFacetOption.fromJson(Map<String, dynamic> json) {
    return CatalogFacetOption(
      optionId: json['optionId']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CatalogFacet {
  final String specId;
  final String slug;
  final CatalogSpecType type;
  final double? min;
  final double? max;
  final List<CatalogFacetOption> options;

  const CatalogFacet({
    required this.specId,
    required this.slug,
    required this.type,
    this.min,
    this.max,
    this.options = const [],
  });

  factory CatalogFacet.fromJson(Map<String, dynamic> json) {
    final options = <CatalogFacetOption>[];
    final raw = json['options'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          options.add(
            CatalogFacetOption.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return CatalogFacet(
      specId: json['specId']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: CatalogSpecType.parse(json['type']?.toString()),
      min: json['min'] is num
          ? (json['min'] as num).toDouble()
          : double.tryParse(json['min']?.toString() ?? ''),
      max: json['max'] is num
          ? (json['max'] as num).toDouble()
          : double.tryParse(json['max']?.toString() ?? ''),
      options: options,
    );
  }
}
