import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/categories/models/category.dart';

const vacuumTrucksSlug = 'vacuum_trucks';

Category? vacuumTrucksCategory(CatalogBundle? catalog) {
  final item = catalog?.categories
      .where((category) => category.slug == vacuumTrucksSlug)
      .firstOrNull;
  if (item == null) return null;
  return Category.fromCatalog(item);
}
