import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/favorites/widgets/favorites_section.dart';
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

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final city = ref.watch(locationProvider).city;

      ref
          .read(equipmentProvider.notifier)
          .getRenterEquipment(
            categoryId: widget.category,
            query: widget.query,
            page: widget.page,
            limit: widget.limit,
            city: city,
          );

      ref.read(favoriteProvider.notifier).getFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ref.watch(equipmentProvider).renterEquipment;
    final bookingNotifier = ref.read(bookingProvider.notifier);

    final locationState = ref.watch(locationProvider);
    final selectedCity = locationState.city;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 60, // Adjust height as needed
              floating: true, // AppBar reappears immediately when scrolling up
              pinned: false, // AppBar hides completely when scrolling down
              backgroundColor: theme.colorScheme.primary,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                "Search",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              centerTitle: false,
              actions: [
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled:
                          true, // Recommended if CityPickerSheet has a list
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
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
                    selectedCity ?? "Select City",
                  ), // Replace with a dynamic state variable
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
                // const SizedBox(width: 8), // Padding from the screen edge
                // IconButton(
                //   onPressed: () =>
                //       setState(() => _isSearchVisible = !_isSearchVisible),
                //   icon: Icon(
                //     Icons.search_rounded,
                //     color: theme.colorScheme.onPrimary,
                //     size: 24,
                //   ),
                //   tooltip: "Search",
                // ),
                // IconButton(
                //   onPressed: () => context.push(AppRoutes.searchMap),
                //   icon: Icon(
                //     Icons.map,
                //     color: theme.colorScheme.onPrimary,
                //     size: 24,
                //   ),
                //   tooltip: "View on Map",
                // ),
              ],
              actionsPadding: EdgeInsets.only(right: 12),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  ],
                ),
              ),
            ),

            // 2. The dynamic list using SliverList
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final equipment = items[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: ClientEquipmentCard(
                    equipment: equipment,
                    onTap: () {
                      bookingNotifier.selectEquipment(equipment);
                      context.push('/equipment/${equipment.id}/book');
                    },
                  ),
                );
              }, childCount: items.length),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              sliver: SliverToBoxAdapter(child: FavoritesSection()),
            ),

            // 3. Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
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
