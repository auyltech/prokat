import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/categories_notifier.dart';

export 'category_dependencies.dart' show categoryServiceProvider;

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, QueryState<Category>>(
      CategoriesNotifier.new,
    );

/// Active catalog group tab for browse/list screens.
final browseCatalogGroupProvider =
    NotifierProvider<BrowseCatalogGroupNotifier, CatalogGroup>(
      BrowseCatalogGroupNotifier.new,
    );

class BrowseCatalogGroupNotifier extends Notifier<CatalogGroup> {
  @override
  CatalogGroup build() => CatalogGroup.machinery;

  void select(CatalogGroup group) => state = group;
}

/// Mutation flows (create request / create equipment): group switch resets
/// category via callers — this provider only holds the active tab.
final mutationCatalogGroupProvider =
    NotifierProvider<MutationCatalogGroupNotifier, CatalogGroup>(
      MutationCatalogGroupNotifier.new,
    );

class MutationCatalogGroupNotifier extends Notifier<CatalogGroup> {
  @override
  CatalogGroup build() => CatalogGroup.machinery;

  void select(CatalogGroup group) => state = group;
}

/// Owner requests / fleet list: active group for server-side filter.
final ownerFleetCatalogGroupProvider =
    NotifierProvider<OwnerFleetCatalogGroupNotifier, CatalogGroup>(
      OwnerFleetCatalogGroupNotifier.new,
    );

class OwnerFleetCatalogGroupNotifier extends Notifier<CatalogGroup> {
  @override
  CatalogGroup build() => CatalogGroup.machinery;

  void select(CatalogGroup group) => state = group;
}

/// Browse/list: selected category kept separately per group.
final selectedBrowseCategoryProvider =
    NotifierProvider<SelectedBrowseCategoryNotifier, Category?>(
      SelectedBrowseCategoryNotifier.new,
    );

class SelectedBrowseCategoryNotifier extends Notifier<Category?> {
  final Map<CatalogGroup, Category?> _byGroup = {
    CatalogGroup.machinery: null,
    CatalogGroup.equipment: null,
  };

  @override
  Category? build() {
    final group = ref.watch(browseCatalogGroupProvider);
    return _byGroup[group];
  }

  void select(Category? category) {
    final group = ref.read(browseCatalogGroupProvider);
    _byGroup[group] = category;
    state = category;
  }

  void toggle(Category category) {
    final group = ref.read(browseCatalogGroupProvider);
    final current = _byGroup[group];
    final next = current?.id == category.id ? null : category;
    _byGroup[group] = next;
    state = next;
  }

  void clear() {
    final group = ref.read(browseCatalogGroupProvider);
    _byGroup[group] = null;
    state = null;
  }
}

/// Backward-compatible alias used by existing search/guest screens.
final selectedCategoryProvider = selectedBrowseCategoryProvider;

List<CatalogGroup> userVisibleCatalogGroups(CatalogBundle? catalog) {
  if (catalog == null) return const [CatalogGroup.machinery];
  return [
    if (catalog.hasUserVisibleMachinery) CatalogGroup.machinery,
    if (catalog.hasUserVisibleEquipment) CatalogGroup.equipment,
  ];
}

List<CatalogGroup> ownerVisibleCatalogGroups(CatalogBundle? catalog) {
  if (catalog == null) return const [CatalogGroup.machinery];
  return [
    if (catalog.hasOwnerVisibleMachinery) CatalogGroup.machinery,
    if (catalog.hasOwnerVisibleEquipment) CatalogGroup.equipment,
  ];
}

CatalogGroup coerceCatalogGroup(
  CatalogGroup preferred,
  List<CatalogGroup> available,
) {
  if (available.isEmpty) return CatalogGroup.machinery;
  if (available.contains(preferred)) return preferred;
  return available.first;
}
