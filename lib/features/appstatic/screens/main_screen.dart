import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/appstatic/widgets/guest_category_section.dart';
import 'package:prokat/features/appstatic/widgets/guest_owner_invite_card.dart';
import 'package:prokat/features/appstatic/widgets/hero_banner.dart';
import 'package:prokat/features/appstatic/widgets/language_sheet.dart';
import 'package:prokat/features/appstatic/state/guest_landing_scroll.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/equipment_list_skeleton.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/equipment/widgets/list/guest_equipment_card.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  Timer? _debounce;
  late final ScrollController _scrollController;
  GuestLandingScroll? _landingScroll;

  ProviderSubscription? _categoriesSub;
  ProviderSubscription? _locationSub;

  Future<void> _fetchData() async {
    if (!mounted) return;

    try {
      final categoryId = ref.read(selectedCategoryProvider)?.id;
      final city = ref.read(locationProvider).city;

      await ref
          .read(guestEquipmentProvider.notifier)
          .setFilters(categoryId: categoryId, city: city);

      if (!mounted) return;

      await ref.read(categoriesProvider.notifier).refreshIfStale();
      await ref.read(catalogProvider.notifier).refreshIfStale();
    } catch (error, stackTrace) {
      // Catalog failures already live in AsyncValue. Swallow them here so the
      // unawaited initState/timer task is not reported as a Crashlytics fatal.
      Logger.log('MainScreen._fetchData failed: $error\n$stackTrace');
    }
  }

  void _loadMore() {
    unawaited(ref.read(guestEquipmentProvider.notifier).loadMore());
  }

  void _onFiltersChanged() {
    _debounce?.cancel();

    _debounce = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      unawaited(_fetchData());
    });
  }

  Future<void> _onRefresh() async {
    try {
      await Future.wait([
        ref.read(catalogProvider.notifier).refresh(),
        ref.read(categoriesProvider.notifier).refresh(),
        ref.read(guestEquipmentProvider.notifier).refresh(),
        ref.read(demandConfigProvider.notifier).refresh(),
      ]);
    } catch (error, stackTrace) {
      Logger.log('MainScreen._onRefresh failed: $error\n$stackTrace');
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _landingScroll = ref.read(guestLandingScrollProvider);
    _landingScroll!.attach(() async {
      if (!_scrollController.hasClients) return;
      if (_scrollController.offset <= 8) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });

    _categoriesSub = ref.listenManual(
      selectedCategoryProvider.select((s) => s?.id),
      (_, _) => _onFiltersChanged(),
    );

    _locationSub = ref.listenManual(
      locationProvider.select((s) => s.city),
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
    _landingScroll?.detach();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    final equipmentAsync = ref.watch(guestEquipmentProvider);
    final queryState = equipmentAsync.valueOrNull;
    final items = queryState?.items ?? [];

    final locationState = ref.watch(locationProvider);
    final selectedCity = locationState.city ?? "";

    const Color darkBlueBg = Color(0xFF071D49);
    const Color brightBlueButton = Color(0xFF2563EB);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
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
              expandedHeight: 340,
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
                  child: EquipmentErrorTile(
                    onRetry: () => unawaited(_onRefresh()),
                  ),
                ),
              )
            else if (items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 40,
                  ),
                  child: EmptyStateTile(
                    imageName: 'empty_equipment.png',
                    title: l10n.noActiveOffers,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
                sliver: SliverList.separated(
                  itemCount: items.length + (queryState!.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
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
                      unawaited(Future.microtask(_loadMore));
                    }

                    return GuestEquipmentCard(item: items[index]);
                  },
                ),
              ),

            const SliverToBoxAdapter(child: GuestOwnerInviteCard()),
            // TODO(Vadim): temporarily hide
            // AboutProkatSection(),
          ],
        ),
      ),
    );
  }
}
