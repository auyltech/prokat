import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/categories/models/category.dart';

class CategoriesNotifier extends AsyncNotifier<QueryState<Category>> {
  static const staleAfter = Duration(hours: 24);

  @override
  Future<QueryState<Category>> build() async {
    final catalog = await ref.watch(catalogProvider.future);
    return _fromCatalog(catalog);
  }

  QueryState<Category> _fromCatalog(CatalogBundle catalog) {
    final items = catalog.userCategories.map(Category.fromCatalog).toList();
    return QueryState(
      items: items,
      page: 1,
      itemsPerPage: items.isEmpty ? 1 : items.length,
      count: items.length,
      lastFetchedAt: DateTime.now(),
    );
  }

  Future<void> refresh() {
    return ref.read(catalogProvider.notifier).refresh();
  }

  Future<void> refreshIfStale() {
    return ref.read(catalogProvider.notifier).refreshIfStale();
  }
}
