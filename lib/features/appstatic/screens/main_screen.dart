import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/appstatic/widgets/show_language_sheet.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/list/guest_equipment_card.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';

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
        .getRenterEquipment(categoryId: categoryId, city: city);

    // Fetch Categories only once
    if (ref.read(categoriesProvider).categories.isEmpty ||
        ref.read(categoriesProvider).error != null) {
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

    final categoriesState = ref.watch(categoriesProvider);
    final equipmentState = ref.watch(equipmentProvider);
    final locationState = ref.watch(locationProvider);

    final selectedCity = locationState.city ?? "";
    final selectedCategory = categoriesState.selectedCategory;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: RichText(
                        softWrap: false,
                        text: TextSpan(
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            const TextSpan(text: 'PRO'),
                            TextSpan(
                              text: 'KAT',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showLanguageSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          langDisplay,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _HeroBanner(city: selectedCity, l10n: l10n),

              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login
                    GestureDetector(
                      onTap: () {
                        context.push(AppRoutes.login);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.getStarted,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.login,
                              size: 24,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Services Header
                    Text(l10n.services, style: theme.textTheme.titleLarge),

                    SizedBox(height: 8),

                    // Categories / Services
                    if (categoriesState.isLoading)
                      EmptyStateTile(title: l10n.loading)
                    else if (categoriesState.error != null)
                      EmptyStateTile(title: l10n.errorLoadingServices)
                    else
                      SizedBox(
                        height: 110, // control height of the row
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categoriesState.categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final category = categoriesState.categories[i];

                            return CategoryCard(
                              isSelected: selectedCategory?.id == category.id,
                              category: category,
                              onTap: () => ref
                                  .watch(categoriesProvider.notifier)
                                  .selectCategory(category),
                            );
                          },
                        ),
                      ),

                    SizedBox(height: 16),

                    // Popular Rents Header
                    Text(l10n.popularRents, style: theme.textTheme.titleLarge),

                    SizedBox(height: 8),

                    if (equipmentState.isLoading)
                      EmptyStateTile(title: l10n.loading)
                    else if (equipmentState.error != null)
                      EmptyStateTile(title: l10n.loadEquipmentErrorHint)
                    else if (equipmentState.renterEquipment.isEmpty)
                      EmptyStateTile(
                        icon: Icons.deselect_outlined,
                        title:
                            "There are no ${selectedCategory?.name ?? "equipment"} listed at this moment ${selectedCity.isNotEmpty ? "in $selectedCity" : ""}",
                      )
                    else
                      // Popular Rents
                      ListView.separated(
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        itemCount: equipmentState.renterEquipment.length,
                        itemBuilder: (context, index) {
                          final item = equipmentState.renterEquipment[index];

                          return GuestEquipmentCard(item: item);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Banner ─────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final String city;
  final AppLocalizations l10n;

  const _HeroBanner({required this.city, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.heroPlatformTag,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.08 * 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.heroTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () =>
                CityPickerSheet.show(context: context, service: "main_screen"),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    city.isNotEmpty ? city : l10n.allLocations,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
