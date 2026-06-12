import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstatic/widgets/guest_category_section.dart';
import 'package:prokat/features/appstatic/widgets/hero_banner.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/show_language_sheet.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/list/guest_equipment_card.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  Timer? _debounce;

  Future<void> _fetchData() async {
    final categoryId = ref.read(categoriesProvider).selectedCategory?.id;
    final city = ref.read(locationProvider).city;

    ref
        .read(equipmentProvider.notifier)
        .getClientEquipment(categoryId: categoryId, city: city);

    // Fetch Categories only once
    if (ref.read(categoriesProvider).isSuccess != true) {
      ref.read(categoriesProvider.notifier).getCategories();
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      // _fetchData();

      ref.listenManual(
        categoriesProvider.select((s) => s.selectedCategory?.id),
        (_, _) => _onFiltersChanged(),
      );

      ref.listenManual(
        locationProvider.select((s) => s.city),
        (_, _) => _onFiltersChanged(),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onFiltersChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    final equipmentState = ref.watch(equipmentProvider);
    final locationState = ref.watch(locationProvider);
    final categoriesState = ref.watch(categoriesProvider);

    final selectedCategory = categoriesState.selectedCategory;
    final selectedCity = locationState.city ?? "All Locations";

    const Color darkBlueBg = Color(0xFF071D49);
    const Color brightBlueButton = Color(0xFF2563EB);

    // const int columns = 3;
    // final int rowCount = (categoriesState.categories.length / columns).ceil();

    // Explicit double calculations to fix typing warnings
    // final double gridHeight = (rowCount * 120.0) + ((rowCount - 1) * 10.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: CustomScrollView(
          slivers: [
            // TOP BAR: Logo, language, search
            // Top Action Header (Stays pinned at the top when collapsed)
            SliverAppBar(
              primary: true,
              pinned: true,
              backgroundColor: darkBlueBg,
              elevation: 0,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: 'PRO'),
                        TextSpan(
                          text: 'KAT',
                          style: TextStyle(color: brightBlueButton),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => showLanguageSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(
                            langDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // const SizedBox(width: 12),

                      // const Icon(Icons.search, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),

            // Middle Bar: Hero Banner
            // Parallax content container
            SliverAppBar(
              primary: false,
              expandedHeight: 420.0,
              backgroundColor: darkBlueBg,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: HeroBanner(selectedCity: selectedCity),
              ),
            ),

            SliverToBoxAdapter(child: GuestCategorySection()),

            // Popular Rents Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  l10n.popularRents,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),

            if (equipmentState.isLoading &&
                equipmentState.renterEquipment.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateTile(title: l10n.loading),
                ),
              )
            else if (equipmentState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateTile(title: l10n.loadEquipmentErrorHint),
                ),
              )
            else if (equipmentState.renterEquipment.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateTile(
                    icon: Icons.deselect_outlined,
                    title:
                        "There are no ${selectedCategory?.name ?? "equipment"} listed at this moment ${selectedCity.isNotEmpty ? "in $selectedCity" : ""}",
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: equipmentState.renterEquipment.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = equipmentState.renterEquipment[index];
                    return GuestEquipmentCard(item: item);
                  },
                ),
              ),

            SliverFillRemaining(
              hasScrollBody:
                  false, // Allows content inside to layout cleanly without nesting scrolls
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  children: [
                    // Automatically pushes your CTA card right down to the absolute screen floor
                    const Spacer(),

                    // ─── GUEST LOGIN CALL-TO-ACTION CARD ────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        // Smooth light color blend or subtle dark tint based on your color modes
                        color: theme.colorScheme.primaryContainer.withAlpha(50),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(30),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Visual Anchor: Bold iconography telling the user there is more to explore
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_person_outlined,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action Heading
                          Text(
                            "Get Started with Prokat",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Context Copy text
                          Text(
                            "Sign in to browse equipment, contact owners directly, place orders in a few taps.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(180),
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // High-Emphasis Execution Button
                          ElevatedButton(
                            onPressed: () {
                              context.push(AppRoutes.login);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              minimumSize: const Size(double.infinity, 52),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Get Started",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.login,
                                  size: 24,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
