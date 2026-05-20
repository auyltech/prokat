import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_empty_tile.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_skeleton.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_trigger.dart';
import 'package:prokat/features/user/widgets/user_category_selector.dart';
import 'package:prokat/features/equipment/widgets/list/client_equipment_card.dart';
import 'package:prokat/l10n/app_localizations.dart';

class SearchEquipmentScreen extends ConsumerStatefulWidget {
  final String? query, category, city;
  final int? page, limit;

  const SearchEquipmentScreen({
    super.key,
    this.query,
    this.category,
    this.city,
    this.page,
    this.limit,
  });

  @override
  ConsumerState<SearchEquipmentScreen> createState() =>
      _SearchEquipmentScreenState();
}

class _SearchEquipmentScreenState extends ConsumerState<SearchEquipmentScreen> {
  // bool _isSearchVisible = false;

  void _loadMore(WidgetRef ref) {
    // Future.microtask ensures we don't trigger state changes during build
    final locationState = ref.watch(locationProvider);
    Future.microtask(
      () => ref
          .read(equipmentProvider.notifier)
          .fetchNextPage(
            categoryId: widget.category,
            query: widget.query,
            city: locationState.city,
          ),
    );
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      // final city = ref.watch(locationProvider).city;

      // ref.read(categoriesProvider.notifier).getCategories();

      // ref
      //     .read(equipmentProvider.notifier)
      //     .initFetch(
      //       categoryId: widget.category,
      //       query: widget.query,
      //       city: city,
      //     );
    });
  }

  Future<void> _onRefresh() async {
    final selectedCity = ref.watch(locationProvider).city;

    final cat = ref.read(categoriesProvider).categories;

    if (cat.isEmpty) ref.read(categoriesProvider.notifier).getCategories();

    ref
        .read(equipmentProvider.notifier)
        .initFetch(
          categoryId: widget.category,
          query: widget.query,
          city: selectedCity,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final equipmentState = ref.watch(equipmentProvider);

    final items = ref.watch(equipmentProvider).renterEquipment;

    final bookingNotifier = ref.read(bookingProvider.notifier);

    final locationState = ref.watch(locationProvider);
    final selectedCity = locationState.city;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          l10n.search,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        centerTitle: false,
        leading: context.canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () => context.pop(),
              )
            : null,
        backgroundColor: theme.primaryColor,
        elevation: 10,
        actions: [CityPickerTrigger(selectedCity: selectedCity)],
        actionsPadding: EdgeInsets.only(right: 8),
      ),
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

              const UserCategorySelector(),

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
                const EquipmentSkeleton()
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
                      Future.microtask(() => _loadMore(ref));
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
