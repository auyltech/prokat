import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/widgets/category_header_card.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/equipment/widgets/client_equipment_tile.dart';
import 'package:prokat/features/equipment/widgets/equipment_list_skeleton.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_empty_tile.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/favorites/widgets/favorites_section.dart';
import 'package:prokat/features/locations/state/location_provider.dart';

class SearchEquipmentScreen extends ConsumerStatefulWidget {
  final String? query;

  const SearchEquipmentScreen({super.key, this.query});

  @override
  ConsumerState<SearchEquipmentScreen> createState() =>
      _SearchEquipmentScreenState();
}

class _SearchEquipmentScreenState extends ConsumerState<SearchEquipmentScreen> {
  Timer? _debounce;

  ProviderSubscription? _categoriesSub;
  ProviderSubscription? _equipmentSub;

  /// Reloads one group's list. [group] is captured when the filter changes so
  /// a later tab switch cannot retarget the request.
  Future<void> _fetchGroup(CatalogGroup group) async {
    if (!mounted) return;

    final categoryId = ref
        .read(selectedBrowseCategoryProvider.notifier)
        .stored(group)
        ?.id;
    final city = ref.read(locationProvider).city;
    final query =
        ref.read(browseGroupSessionsProvider.notifier).peek(group)?.query ?? '';
    final equipment = ref.read(clientEquipmentProvider(group).notifier);
    final favorites = ref.read(favoritesProvider.notifier);
    final categories = ref.read(categoriesProvider.notifier);
    final catalog = ref.read(catalogProvider.notifier);

    await equipment.search(
      categoryId: categoryId,
      city: city,
      query: query,
      spec: const [],
    );

    if (!mounted) return;
    await favorites.getFavorites();

    if (!mounted) return;
    await categories.refreshIfStale();

    if (!mounted) return;
    await catalog.refreshIfStale();
  }

  void _scheduleFetch(CatalogGroup group) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(_fetchGroup(group));
    });
  }

  /// Tab switch republishes the other group's category through
  /// [selectedCategoryProvider]. That is not a filter change: the opened list
  /// already holds its own category and query.
  bool _listMatchesStoredFilters(CatalogGroup group) {
    final storedCategoryId = _emptyToNull(
      ref.read(selectedBrowseCategoryProvider.notifier).stored(group)?.id,
    );
    final storedQuery = _emptyToNull(
      ref.read(browseGroupSessionsProvider.notifier).peek(group)?.query,
    );
    final storedCity = _emptyToNull(ref.read(locationProvider).city);
    final provider = clientEquipmentProvider(group);
    if (!ref.exists(provider)) {
      return storedCategoryId == null && storedQuery == null;
    }

    final applied = ref.read(provider.notifier);
    return applied.categoryId == storedCategoryId &&
        applied.query == storedQuery &&
        applied.city == storedCity;
  }

  void _onCategoryChanged() {
    final group = ref.read(browseCatalogGroupProvider);
    if (_listMatchesStoredFilters(group)) return;
    _scheduleFetch(group);
  }

  void _onQueryChanged() {
    if (!mounted) return;
    final group = ref.read(browseCatalogGroupProvider);
    if (_listMatchesStoredFilters(group)) return;
    unawaited(_fetchGroup(group));
  }

  @override
  void initState() {
    super.initState();

    _categoriesSub = ref.listenManual(
      selectedCategoryProvider.select((s) => s?.id),
      (previous, next) {
        if (previous == next) return;
        _onCategoryChanged();
      },
    );

    _equipmentSub = ref.listenManual(
      currentBrowseGroupSessionProvider.select((s) => s.query),
      (previous, next) {
        if (previous == next) return;
        _onQueryChanged();
      },
    );

    unawaited(
      Future.microtask(() async {
        if (!mounted) return;
        final group = ref.read(browseCatalogGroupProvider);
        ref.read(browseGroupSessionsProvider.notifier).ensure(group);
        await _fetchGroup(group);
      }),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _categoriesSub?.close();
    _equipmentSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(categoriesProvider);

    final catalog = ref.watch(catalogProvider);
    if (!catalog.hasValue) {
      return const Scaffold(
        body: SafeArea(top: false, child: EquipmentListSkeleton()),
      );
    }
    final groups = userVisibleCatalogGroups(catalog.value);
    final selected = coerceCatalogGroup(
      ref.watch(browseCatalogGroupProvider),
      groups,
    );

    final pages = [
      for (final group in groups)
        _SearchGroupPage(key: ValueKey(group), group: group),
    ];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: FavoritesOverlay(
          child: groups.length < 2
              ? pages.first
              : AppTabs(
                  initialIndex: groups.indexOf(selected),
                  titles: [
                    for (final group in groups)
                      _searchTabTitle(AppLocalizations.of(context)!, group),
                  ],
                  onChanged: (index) {
                    final group = groups[index];
                    ref
                        .read(browseGroupSessionsProvider.notifier)
                        .ensure(group);
                    ref.read(browseCatalogGroupProvider.notifier).select(group);
                  },
                  children: pages,
                ),
        ),
      ),
    );
  }
}

String? _emptyToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _searchTabTitle(AppLocalizations l10n, CatalogGroup group) {
  return switch (group) {
    CatalogGroup.machinery => l10n.searchMachineryTab,
    CatalogGroup.equipment => l10n.searchEquipmentTab,
  };
}

class _SearchGroupPage extends ConsumerStatefulWidget {
  const _SearchGroupPage({super.key, required this.group});

  final CatalogGroup group;

  @override
  ConsumerState<_SearchGroupPage> createState() => _SearchGroupPageState();
}

class _SearchGroupPageState extends ConsumerState<_SearchGroupPage> {
  Future<void> _reload() {
    return Future.wait([
      ref.read(catalogProvider.notifier).refresh(),
      ref.read(categoriesProvider.notifier).refresh(),
      ref.read(demandConfigProvider.notifier).refresh(),
      ref.read(clientEquipmentProvider(widget.group).notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final equipmentAsync = ref.watch(clientEquipmentProvider(widget.group));
    final queryState = equipmentAsync.valueOrNull;
    final items = queryState?.items ?? [];
    final bookingNotifier = ref.read(bookingMutationProvider.notifier);

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(AppDimens.s16$base),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          CategoryHeaderCard(group: widget.group),
          const SizedBox(height: AppDimens.s16$base),
          if (equipmentAsync.isLoading && items.isEmpty)
            const EquipmentListSkeleton()
          else if (equipmentAsync.hasError)
            EquipmentErrorTile(onRetry: () => unawaited(_reload()))
          else if (items.isEmpty)
            const EquipmentEmptyTile()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemCount: items.length + (queryState!.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (index == items.length - 1 &&
                    queryState.hasMore &&
                    !queryState.isLoadingMore &&
                    !queryState.isRefreshing) {
                  unawaited(
                    Future.microtask(
                      () => ref
                          .read(clientEquipmentProvider(widget.group).notifier)
                          .loadMore(),
                    ),
                  );
                }

                final equipment = items[index];
                return ClientEquipmentTile(
                  equipment: equipment,
                  onTap: () {
                    bookingNotifier.selectEquipment(equipment);
                    unawaited(
                      context.push(
                        '${AppRoutes.equipment}/${equipment.id}/${AppRoutes.book}',
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
