import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/widgets/user_category_selector.dart';
import 'package:prokat/features/equipment/providers/client_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/client_equipment_tile.dart';
import 'package:prokat/features/equipment/widgets/equipment_list_skeleton.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_empty_tile.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/equipment/widgets/spec_filter_panel.dart';
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
  ProviderSubscription? _locationSub;
  ProviderSubscription? _equipmentSub;
  ProviderSubscription? _specSub;

  Future<void> _fetchData() async {
    final categoryId = ref.read(selectedCategoryProvider)?.id;
    final city = ref.read(locationProvider).city;
    final query = ref.read(searchEquipmentProvider).query;
    final spec = ref.read(specFilterQueryProvider);

    await ref
        .read(clientEquipmentProvider.notifier)
        .search(categoryId: categoryId, city: city, query: query, spec: spec);

    if (!mounted) return;
    await ref.read(favoritesProvider.notifier).getFavorites();

    await ref.read(categoriesProvider.notifier).refreshIfStale();
    await ref.read(catalogProvider.notifier).refreshIfStale();
  }

  void _loadMore() {
    unawaited(ref.read(clientEquipmentProvider.notifier).loadMore());
  }

  void _onFiltersChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_fetchData());
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(catalogProvider.notifier).refresh(),
      ref.read(clientEquipmentProvider.notifier).refresh(),
      ref.read(categoriesProvider.notifier).refresh(),
      ref.read(demandConfigProvider.notifier).refresh(),
    ]);
  }

  @override
  void initState() {
    super.initState();

    _categoriesSub = ref.listenManual(
      selectedCategoryProvider.select((s) => s?.id),
      (_, _) => _onFiltersChanged(),
    );

    _locationSub = ref.listenManual(
      locationProvider.select((s) => s.city),
      (_, _) => _onFiltersChanged(),
    );

    _equipmentSub = ref.listenManual(
      searchEquipmentProvider.select((s) => s.query),
      (_, _) => _fetchData(),
    );

    _specSub = ref.listenManual(
      specFilterQueryProvider,
      (_, _) => _onFiltersChanged(),
    );

    unawaited(
      Future.microtask(() async {
        if (!mounted) return;
        await _fetchData();
      }),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _categoriesSub?.close();
    _locationSub?.close();
    _equipmentSub?.close();
    _specSub?.close();
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
    final selectedCategoryId = ref.watch(selectedCategoryProvider)?.id;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: FavoritesOverlay(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SearchBox(placeholder: l10n.searchEquipment),

                const SizedBox(height: 12),

                UserCategorySelector(
                  mode: "search",
                  selectedCategoryId: selectedCategoryId,
                ),

                const SizedBox(height: 12),

                const SpecFilterPanel(),

                const SizedBox(height: 12),

                SectionTitle(title: l10n.search),

                const SizedBox(height: 12),

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
