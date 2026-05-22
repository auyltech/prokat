import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/providers/locale_provider.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/appstatic/widgets/show_language_sheet.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/list/guest_equipment_card.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';

const Color kBlue = Color(0xFF2563EB);
const Color kBlueDark = Color(0xFF1E3A8A);
const Color kBgGray = Color(0xFFF8F9FB);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextPrimary = Color(0xFF111827);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kTextMuted = Color(0xFF9CA3AF);

const List<String> kLanguages = ['RU', 'KZ', 'EN'];

const kazakhstanCities = [
  'Almaty',
  'Astana',
  'Shymkent',
  'Atyrau',
  'Aktobe',
  'Karaganda',
  'Taraz',
  'Pavlodar',
  'Ust-Kamenogorsk',
  'Semey',
  'Kostanay',
  'Kyzylorda',
  'Uralsk',
  'Petropavl',
  'Turkistan',
];

class MainScreen extends ConsumerStatefulWidget {
  final String? query, category, city;
  final int? page, limit;

  const MainScreen({
    super.key,
    this.query,
    this.category,
    this.city,

    this.page,
    this.limit,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  Timer? _debounce;

  Future<void> _fetchData() async {
    ref
        .read(equipmentProvider.notifier)
        .getRenterEquipment(
          categoryId: widget.category,
          query: widget.query,
          page: widget.page,
          limit: widget.limit,
          city: widget.city,
        );

    if (ref.read(categoriesProvider).categories.isEmpty ||
        ref.read(categoriesProvider).error != null) {
      ref.read(categoriesProvider.notifier).getCategories();
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchData());
  }

  void _updateFilters(BuildContext context, Map<String, String?> newParams) {
    final uri = GoRouterState.of(context).uri;
    final currentParams = Map<String, String>.from(uri.queryParameters);

    newParams.forEach((key, value) {
      if (value == null) {
        currentParams.remove(key);
      } else {
        currentParams[key] = value;
      }
    });

    currentParams['page'] = '1';

    context.go(
      Uri(path: AppRoutes.main, queryParameters: currentParams).toString(),
    );
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final paramsChanged =
        oldWidget.query != widget.query ||
        oldWidget.city != widget.city ||
        oldWidget.category != widget.category ||
        oldWidget.page != widget.page;

    if (paramsChanged) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(seconds: 2), () {
        ref
            .read(equipmentProvider.notifier)
            .getRenterEquipment(
              city: widget.city ?? "",
              categoryId: widget.category ?? "",
              query: widget.query ?? "",
              page: widget.page ?? 1,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final langDisplay = LocaleNotifier.displayCode(locale);

    final categoriesState = ref.watch(categoriesProvider);
    final equipmentState = ref.watch(equipmentProvider);

    final selectedCity = widget.city ?? "";
    final selectedCategory = widget.category ?? "";

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

              _HeroBanner(
                city: selectedCity,
                l10n: l10n,
                onCityTap: () => CityPickerSheet.show(
                  context: context,
                  city: selectedCity,
                  mode: "guest",
                ),
              ),

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
                          borderRadius: BorderRadius.circular(12),
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
                              isSelected: selectedCategory == category.id,
                              category: category,
                              onTap: () => _updateFilters(context, {
                                'category': category.id,
                              }),
                            );
                          },
                        ),
                      ),

                    SizedBox(height: 12),

                    // Popular Rents Header
                    Text(l10n.popularRents, style: theme.textTheme.titleLarge),

                    SizedBox(height: 8),

                    if (equipmentState.isLoading)
                      EmptyStateTile(title: l10n.loading)
                    else if (equipmentState.error != null)
                      EmptyStateTile(title: l10n.loadEquipmentErrorHint)
                    else
                      // Popular Rents
                      ListView.builder(
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
  final VoidCallback onCityTap;

  const _HeroBanner({
    required this.city,
    required this.l10n,
    required this.onCityTap,
  });

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
            onTap: onCityTap,
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

// ─── Filter Pills ─────────────────────────────────────────────────────────────
const List<String> kFilters = ['All', 'Daily', 'Weekly', 'Monthly', 'Near me'];
