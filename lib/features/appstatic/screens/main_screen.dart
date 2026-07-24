import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/appstatic/widgets/about_prokat.dart';
import 'package:prokat/features/appstatic/widgets/guest_category_section.dart';
import 'package:prokat/features/appstatic/widgets/hero_banner.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/equipment_list_skeleton.dart';
import 'package:prokat/features/equipment/widgets/list/guest_equipment_card.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  Timer? _debounce;

  ProviderSubscription? _categoriesSub;
  ProviderSubscription? _locationSub;

  Future<void> _fetchData() async {
    final categoryState = ref.read(categoriesProvider);
    final categoryNotifier = ref.read(categoriesProvider.notifier);

    final categoryId = categoryState.selectedCategory?.id;
    final city = ref.read(locationProvider).city;

    await ref
        .read(guestEquipmentProvider.notifier)
        .setFilters(categoryId: categoryId, city: city);

    ref.read(guestEquipmentProvider.notifier).refresh();

    if (categoryState.fetchStatus == FetchStatus.initial ||
        categoryState.fetchStatus == FetchStatus.error) {
      categoryNotifier.getCategories();
      return;
    }

    if (categoryState.lastFetchedAt != null) {
      final age = DateTime.now().difference(categoryState.lastFetchedAt!);

      if (age.inMinutes >= 5) {
        categoryNotifier.getCategories();
      }
    }
  }

  void _loadMore() {
    ref.read(guestEquipmentProvider.notifier).loadMore();
  }

  void _onFiltersChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      _fetchData();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(guestEquipmentProvider.notifier).refresh();

    final categoryState = ref.read(categoriesProvider);

    if (categoryState.fetchStatus == FetchStatus.initial ||
        categoryState.fetchStatus == FetchStatus.error) {
      ref.read(categoriesProvider.notifier).getCategories();
      return;
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await _fetchData();

      _categoriesSub = ref.listenManual(
        categoriesProvider.select((s) => s.selectedCategory?.id),
        (_, _) => _onFiltersChanged(),
      );

      _locationSub = ref.listenManual(
        locationProvider.select((s) => s.city),
        (_, _) => _onFiltersChanged(),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _categoriesSub?.close();
    _locationSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    final equipmentAsync = ref.watch(guestEquipmentProvider);
    final queryState = equipmentAsync.value;
    final items = queryState?.items ?? [];

    final locationState = ref.watch(locationProvider);
    final categoriesState = ref.watch(categoriesProvider);

    final selectedCategory = categoriesState.selectedCategory;
    final selectedCity = locationState.city ?? "";

    const Color darkBlueBg = Color(0xFF071D49);
    const Color brightBlueButton = Color(0xFF2563EB);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              primary: true,
              pinned: true,
              backgroundColor: darkBlueBg,
              elevation: 0,
              automaticallyImplyLeading: false,
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
                  GestureDetector(
                    onTap: () => LanguageSheet.show(context),
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
                ],
              ),
            ),

            SliverAppBar(
              primary: false,
              expandedHeight: 420,
              backgroundColor: darkBlueBg,
              automaticallyImplyLeading: false,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: HeroBanner(selectedCity: selectedCity),
              ),
            ),

            const SliverToBoxAdapter(child: GuestCategorySection()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: SectionTitle(title: l10n.popularRents),
              ),
            ),

            if (equipmentAsync.isLoading && items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: EquipmentListSkeleton(),
                ),
              )
            else if (equipmentAsync.hasError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyStateTile(title: l10n.loadEquipmentErrorHint),
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: EmptyStateTile(
                    icon: Icons.deselect_outlined,
                    title: selectedCity.isNotEmpty
                        ? l10n.noEquipmentListedInCity(
                            selectedCategory?.name ?? l10n.navEquipment,
                            selectedCity,
                          )
                        : l10n.noEquipmentForCategory(
                            selectedCategory?.name ?? l10n.navEquipment,
                          ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: items.length + (queryState!.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (index == items.length - 1 &&
                        queryState.hasMore &&
                        !queryState.isLoadingMore) {
                      Future.microtask(_loadMore);
                    }

                    return GuestEquipmentCard(item: items[index]);
                  },
                ),
              ),

            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                // 1. Solid surface background to cleanly alternate with your dark blue hero below
                color: theme.colorScheme.surface,
                child: Padding(
                  // 2. Tall vertical padding to give the login block its own massive hero presence
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 3. Ultra-clean minimalist icon wrapper with no heavy boarders
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_person_outlined,
                          size: 38,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. Bolder, larger headline that commands the screen
                      Text(
                        l10n.getStartedWithProkat,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 5. Spacious, legible description paragraph
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.guestSignInDescription,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                            fontWeight: FontWeight.w400,
                            height: 1.55,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 6. Premium full-width brand primary action button
                      ElevatedButton(
                        onPressed: () {
                          context.push(AppRoutes.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(
                            double.infinity,
                            56,
                          ), // Tall modern button height
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.getStarted,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            AboutProkatSection(),
          ],
        ),
      ),
    );
  }
}
