import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_empty_tile.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_list_skeleton.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/categories/widgets/user_category_selector.dart';
import 'package:prokat/features/equipment/widgets/list/client_equipment_card.dart';
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

  // Fetch on first screen load and then on filters change
  Future<void> _fetchData() async {
    final categoryId = ref.read(categoriesProvider).selectedCategory?.id;
    final city = ref.read(locationProvider).city;
    final query = ref.read(equipmentProvider).query;

    ref
        .read(equipmentProvider.notifier)
        .initFetch(categoryId: categoryId, city: city, query: query);

    // Fetch Categories only once
    if (ref.read(categoriesProvider).categories.isEmpty ||
        ref.read(categoriesProvider).error != null) {
      ref.read(categoriesProvider.notifier).getCategories();
    }
  }

  void _loadMore() {
    final categoryId = ref.read(categoriesProvider).selectedCategory?.id;
    final city = ref.read(locationProvider).city;

    ref
        .read(equipmentProvider.notifier)
        .fetchNextPage(categoryId: categoryId, query: widget.query, city: city);

    // Fetch Categories only once
    if (ref.read(categoriesProvider).categories.isEmpty ||
        ref.read(categoriesProvider).error != null) {
      ref.read(categoriesProvider.notifier).getCategories();
    }
  }

  void _onFiltersChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      _fetchData();
    });
  }

  Future<void> _onRefresh() async {
    _fetchData();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      _fetchData();

      ref.listenManual(
        categoriesProvider.select((s) => s.selectedCategory?.id),
        (_, _) => _onFiltersChanged(),
      );

      ref.listenManual(
        locationProvider.select((s) => s.city),
        (_, _) => _onFiltersChanged(),
      );

      // Query is debounced inside the search box
      ref.listenManual(
        equipmentProvider.select((s) => s.query),
        (_, _) => _fetchData(),
      );
    });
  }

  @override
  void dispose() {
    // Always close manual subscriptions to prevent memory leaks!
    _categoriesSub?.close();
    _locationSub?.close();
    _equipmentSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final equipmentState = ref.watch(equipmentProvider);

    final items = ref.watch(equipmentProvider).renterEquipment;

    final bookingNotifier = ref.read(bookingProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SearchBox(placeholder: l10n.searchEquipment),

              const SizedBox(height: 24),

              const UserCategorySelector(mode: "search"),

              const SizedBox(height: 12),

              Text(
                l10n.search,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 12),

              // Equipment List
              if (equipmentState.isLoading)
                const EquipmentListSkeleton()
              else if (equipmentState.error != null)
                EquipmentErrorTile(
                  onRetry: () => ref.invalidate(equipmentProvider),
                )
              else if (items.isEmpty)
                const EquipmentEmptyTile()
              else
                ListView.separated(
                  separatorBuilder: (_, _) => SizedBox(height: 18),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const SizedBox.shrink();
                    }

                    if (index == items.length - 1) {
                      // Use microtask to delay execution until the layout build pass completes safely
                      Future.microtask(() => _loadMore());
                    }

                    final equipment = items[index];

                    return ClientEquipmentCard(
                      equipment: equipment,
                      onTap: () {
                        bookingNotifier.selectEquipment(equipment);
                        context.push('/equipment/${equipment.id}/book');
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
