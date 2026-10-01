import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';

/// Owner fleet groups from GET /equipment/owner/catalog-groups.
/// Used for owner requests / fleet list tabs (not catalog visibility).
final ownerFleetGroupsProvider = FutureProvider.autoDispose<List<CatalogGroup>>(
  (ref) async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) return const [CatalogGroup.machinery];

    final response = await ref
        .watch(equipmentServiceProvider)
        .getOwnerCatalogGroups();
    if (!response.success || response.data == null) {
      return const [CatalogGroup.machinery];
    }

    final groups = response.data!.map(CatalogGroup.fromApi).toSet().toList();
    if (groups.isEmpty) return const [CatalogGroup.machinery];
    groups.sort((a, b) => a.index.compareTo(b.index));
    return groups;
  },
);

/// Groups already present on the owner's loaded listings.
List<CatalogGroup> catalogGroupsIn(Iterable<Equipment> items) {
  final groups = items
      .map((item) => item.category?.catalogGroup)
      .whereType<CatalogGroup>()
      .toSet()
      .toList();
  groups.sort((a, b) => a.index.compareTo(b.index));
  return groups;
}

/// Which fleet tabs to show.
///
/// Listings win when they already contain both groups, so a reload of
/// [ownerFleetGroupsProvider] cannot briefly draw one mixed list.
List<CatalogGroup> resolveOwnerFleetGroups({
  required List<CatalogGroup>? fetched,
  required Iterable<Equipment> items,
}) {
  final fromItems = catalogGroupsIn(items);
  if (fromItems.length > 1) return fromItems;
  if (fetched != null && fetched.isNotEmpty) return fetched;
  return fromItems;
}
