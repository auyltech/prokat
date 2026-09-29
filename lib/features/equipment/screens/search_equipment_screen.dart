import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/categories/widgets/category_header_card.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/client_equipment_tile.dart';
import 'package:prokat/features/equipment/widgets/equipment_list_skeleton.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_empty_tile.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/favorites/widgets/favorites_section.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
  ProviderSubscription? _catalogGroupSub;
  ProviderSubscription? _locationSub;
  ProviderSubscription? _equipmentSub;

  Future<void> _fetchData() async {
    if (!mounted) return;

    final categoryId = ref.read(selectedCategoryProvider)?.id;
    final catalogGroup = ref.read(browseCatalogGroupProvider);
    final city = ref.read(locationProvider).city;
    final query = ref
        .read(browseGroupSessionsProvider.notifier)
        .ensure(catalogGroup)
        .query;
    final equipment = ref.read(clientEquipmentProvider.notifier);
    final favorites = ref.read(favoritesProvider.notifier);
    final categories = ref.read(categoriesProvider.notifier);
    final catalog = ref.read(catalogProvider.notifier);

    await equipment.search(
      categoryId: categoryId,
      catalogGroup: catalogGroup.apiValue,
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

  void _loadMore() {
    if (!mounted) return;
    unawaited(ref.read(clientEquipmentProvider.notifier).loadMore());
  }

  void _onFiltersChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(_fetchData());
    });
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    final catalog = ref.read(catalogProvider.notifier);
    final equipment = ref.read(clientEquipmentProvider.notifier);
    final categories = ref.read(categoriesProvider.notifier);
    final demand = ref.read(demandConfigProvider.notifier);

    await Future.wait([
      catalog.refresh(),
      equipment.refresh(),
      categories.refresh(),
      demand.refresh(),
    ]);
  }

  @override
  void initState() {
    super.initState();

    _categoriesSub = ref.listenManual(
      selectedCategoryProvider.select((s) => s?.id),
      (_, _) => _onFiltersChanged(),
    );

    _catalogGroupSub = ref.listenManual(
      browseCatalogGroupProvider,
      (_, _) => _onFiltersChanged(),
    );

    _locationSub = ref.listenManual(
      locationProvider.select((s) => s.city),
      (_, _) => _onFiltersChanged(),
    );

    _equipmentSub = ref.listenManual(
      currentBrowseGroupSessionProvider.select((s) => s.query),
      (_, _) {
        if (!mounted) return;
        unawaited(_fetchData());
      },
    );

    unawaited(
      Future.microtask(() async {
        if (!mounted) return;
        ref
            .read(browseGroupSessionsProvider.notifier)
            .ensure(ref.read(browseCatalogGroupProvider));
        await _fetchData();
      }),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _categoriesSub?.close();
    _catalogGroupSub?.close();
    _locationSub?.close();
    _equipmentSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final equipmentAsync = ref.watch(clientEquipmentProvider);
    final queryState = equipmentAsync.valueOrNull;

    final items = queryState?.items ?? [];

    final bookingNotifier = ref.read(bookingMutationProvider.notifier);

    ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: FavoritesOverlay(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.s16$base),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                CatalogGroupTabs(
                  groups: userVisibleCatalogGroups(
                    ref.watch(catalogProvider).valueOrNull,
                  ),
                  selected: ref.watch(browseCatalogGroupProvider),
                  onChanged: (group) {
                    ref
                        .read(browseGroupSessionsProvider.notifier)
                        .ensure(group);
                    ref.read(browseCatalogGroupProvider.notifier).select(group);
                  },
                ),

                const SizedBox(height: AppDimens.s12$md),

                const CategoryHeaderCard(),

                const SizedBox(height: AppDimens.s16$base),

                if (equipmentAsync.isLoading && items.isEmpty)
                  const EquipmentListSkeleton()
                else if (equipmentAsync.hasError)
                  EquipmentErrorTile(onRetry: () => unawaited(_onRefresh()))
                else if (items.isEmpty)
                  const EquipmentEmptyTile()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemCount:
                        items.length + (queryState!.isLoadingMore ? 1 : 0),
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
                        unawaited(Future.microtask(_loadMore));
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
          ),
        ),
      ),
    );
  }
}
