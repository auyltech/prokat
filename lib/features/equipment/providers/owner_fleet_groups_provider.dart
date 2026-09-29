import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
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
