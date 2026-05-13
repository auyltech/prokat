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
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/features/user/widgets/user_category_selector.dart';
import 'package:prokat/features/equipment/widgets/list/client_equipment_card.dart';

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
    final city = ref.watch(locationProvider).city;

    ref.read(categoriesProvider.notifier).getCategories();

    ref
        .read(equipmentProvider.notifier)
        .initFetch(
          categoryId: widget.category,
          query: widget.query,
          city: city,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final equipmentState = ref.watch(equipmentProvider);

    final items = ref.watch(equipmentProvider).renterEquipment;

    final bookingNotifier = ref.read(bookingProvider.notifier);

    final locationState = ref.watch(locationProvider);
    final selectedCity = locationState.city;

    print(items.length);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Search",
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled:
                    true, // Recommended if CityPickerSheet has a list
                backgroundColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.7, // Opens at 70% height
                    maxChildSize: 0.9, // Can be dragged up to 90%
                    minChildSize: 0.4, // Can be dragged down to 40%
                    expand: false,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: CityPickerSheet(
                          // IMPORTANT: Pass this controller to your ListView/GridView
                          scrollController: scrollController,
                        ),
                      );
                    },
                  );
                },
              );
            },
            icon: Icon(
              Icons.location_on_outlined,
              size: 20,
              color: theme.colorScheme.onPrimary,
            ),
            label: Text(
              (selectedCity ?? "").isEmpty
                  ? "Select City"
                  : (selectedCity ?? ""),
              style: TextStyle(fontWeight: FontWeight.w400),
            ), // Replace with a dynamic state variable
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SearchBox(),

              const SizedBox(height: 24),

              const UserCategorySelector(),

              const SizedBox(height: 12),

              Text(
                "Search",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

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
                ListView.builder(
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

class AnimatedVisibility extends StatelessWidget {
  final bool visible;
  final Widget child;

  const AnimatedVisibility({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: child,
      secondChild: const SizedBox(width: double.infinity),
      crossFadeState: visible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 250),
    );
  }
}
