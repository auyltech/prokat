import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';

class Category {
  final String id;
  final String name;
  final int sortIndex;
  final String? imageUrl;
  final String? slug;
  final LocalizedNames names;

  const Category({
    required this.id,
    required this.name,
    required this.sortIndex,
    this.imageUrl,
    this.slug,
    this.names = const LocalizedNames(),
  });

  factory Category.fromCatalog(CatalogCategory item) {
    final fallback = item.slug.isNotEmpty ? item.slug : item.id;
    return Category(
      id: item.id,
      name: item.names.pick('en', fallback: fallback),
      sortIndex: item.sortIndex,
      imageUrl: item.imageUrl,
      slug: item.slug,
      names: item.names,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final names = LocalizedNames.fromJson(json['names']);
    final name = json['name']?.toString() ?? '';
    return Category(
      id: json['id'] ?? '',
      name: name.isNotEmpty ? name : names.pick('en'),
      sortIndex: (json['sortIndex'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      slug: json['slug']?.toString(),
      names: names,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sortIndex': sortIndex,
      'imageUrl': imageUrl,
      'slug': slug,
      'names': names.toJson(),
    };
  }

  String localizedName(String languageCode) {
    return names.pick(languageCode, fallback: name);
  }
}
