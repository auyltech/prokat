import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/state/category_provider.dart';

/// Per-group browse UI session (search field, expand, future filters).
///
/// `null` in the map means the tab was never opened (lazy).
/// Once [ensure] runs, the session sticks across tab switches.
@immutable
class BrowseGroupSession {
  final String query;
  final bool searchExpanded;

  const BrowseGroupSession({this.query = '', this.searchExpanded = false});

  BrowseGroupSession copyWith({String? query, bool? searchExpanded}) {
    return BrowseGroupSession(
      query: query ?? this.query,
      searchExpanded: searchExpanded ?? this.searchExpanded,
    );
  }
}

final browseGroupSessionsProvider =
    NotifierProvider<
      BrowseGroupSessionsNotifier,
      Map<CatalogGroup, BrowseGroupSession?>
    >(BrowseGroupSessionsNotifier.new);

class BrowseGroupSessionsNotifier
    extends Notifier<Map<CatalogGroup, BrowseGroupSession?>> {
  @override
  Map<CatalogGroup, BrowseGroupSession?> build() => {
    CatalogGroup.machinery: null,
    CatalogGroup.equipment: null,
  };

  /// First open of a tab creates a default session; later opens reuse it.
  BrowseGroupSession ensure(CatalogGroup group) {
    final existing = state[group];
    if (existing != null) return existing;
    const created = BrowseGroupSession();
    state = {...state, group: created};
    return created;
  }

  BrowseGroupSession forCurrentGroup() {
    return ensure(ref.read(browseCatalogGroupProvider));
  }

  BrowseGroupSession? peek(CatalogGroup group) => state[group];

  bool isInitialized(CatalogGroup group) => state[group] != null;

  void setQuery(String query) {
    final group = ref.read(browseCatalogGroupProvider);
    final current = ensure(group);
    if (current.query == query) return;
    state = {...state, group: current.copyWith(query: query)};
  }

  void setSearchExpanded(bool expanded) {
    final group = ref.read(browseCatalogGroupProvider);
    final current = ensure(group);
    if (current.searchExpanded == expanded) return;
    state = {...state, group: current.copyWith(searchExpanded: expanded)};
  }

  /// Clears search UI for the active group (category pick / close search).
  void clearSearch() {
    final group = ref.read(browseCatalogGroupProvider);
    final current = ensure(group);
    if (current.query.isEmpty && !current.searchExpanded) return;
    state = {
      ...state,
      group: current.copyWith(query: '', searchExpanded: false),
    };
  }
}

/// Active group's session (empty default if tab not ensured yet).
final currentBrowseGroupSessionProvider = Provider<BrowseGroupSession>((ref) {
  final group = ref.watch(browseCatalogGroupProvider);
  final sessions = ref.watch(browseGroupSessionsProvider);
  return sessions[group] ?? const BrowseGroupSession();
});
