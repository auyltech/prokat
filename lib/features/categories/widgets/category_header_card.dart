import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_filters_stub_sheet.dart';
import 'package:prokat/features/categories/widgets/category_picker_sheet.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Expandable category header: image + title/description + filter/search.
///
/// Search UI is per catalog-group session (lazy + sticky across tabs).
/// Filter modal is a stub until catalog filters ship.
class CategoryHeaderCard extends ConsumerStatefulWidget {
  const CategoryHeaderCard({super.key});

  @override
  ConsumerState<CategoryHeaderCard> createState() => _CategoryHeaderCardState();
}

class _CategoryHeaderCardState extends ConsumerState<CategoryHeaderCard> {
  static const _imageSize = 100.0;

  late final TextEditingController _searchController;
  Timer? _debounce;
  ProviderSubscription<CatalogGroup>? _groupSub;

  @override
  void initState() {
    super.initState();
    final sessions = ref.read(browseGroupSessionsProvider.notifier);
    final group = ref.read(browseCatalogGroupProvider);
    // Peek only — do not mutate providers during initState/build.
    final existing = sessions.peek(group);
    _searchController = TextEditingController(text: existing?.query ?? '');

    _groupSub = ref.listenManual(browseCatalogGroupProvider, (previous, next) {
      if (previous == next) return;
      final restored = sessions.ensure(next);
      _debounce?.cancel();
      _searchController.value = TextEditingValue(
        text: restored.query,
        selection: TextSelection.collapsed(offset: restored.query.length),
      );
      _syncSearchProvider(restored.query);
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = sessions.ensure(group);
      if (_searchController.text != session.query) {
        _searchController.value = TextEditingValue(
          text: session.query,
          selection: TextSelection.collapsed(offset: session.query.length),
        );
      }
      _syncSearchProvider(session.query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _groupSub?.close();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters => false;

  void _syncSearchProvider(String query) {
    ref.read(searchEquipmentProvider.notifier).setQuery(query);
  }

  void _setQuery(String value) {
    ref.read(browseGroupSessionsProvider.notifier).setQuery(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _syncSearchProvider(value);
    });
  }

  void _collapseSearch({required bool clearQuery}) {
    _debounce?.cancel();
    final sessions = ref.read(browseGroupSessionsProvider.notifier);
    if (clearQuery) {
      _searchController.clear();
      sessions.clearSearch();
      _syncSearchProvider('');
    } else {
      sessions.setSearchExpanded(false);
    }
    setState(() {});
  }

  void _toggleSearch() {
    final sessions = ref.read(browseGroupSessionsProvider.notifier);
    final session = sessions.forCurrentGroup();
    if (session.searchExpanded) {
      _collapseSearch(clearQuery: true);
      return;
    }
    sessions.setSearchExpanded(true);
    setState(() {});
  }

  Future<void> _openFilters() async {
    await CategoryFiltersStubSheet.show(context);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openCategoryPicker({
    required List<Category> categories,
    required CatalogGroup group,
  }) async {
    final selected = await CategoryPickerSheet.show(
      context,
      categories: categories,
      group: group,
      selectedId: ref.read(selectedBrowseCategoryProvider)?.id,
    );
    if (!mounted || selected == null) return;

    _collapseSearch(clearQuery: true);

    if (selected.isAll) {
      ref.read(selectedBrowseCategoryProvider.notifier).clear();
    } else {
      ref
          .read(selectedBrowseCategoryProvider.notifier)
          .select(selected.category);
    }
  }

  String _allCategoriesDescription(AppLocalizations l10n, CatalogGroup group) {
    return group == CatalogGroup.equipment
        ? l10n.allCategoriesEquipmentDescription
        : l10n.allCategoriesMachineryDescription;
  }

  AppImage _allCategoriesImage(CatalogGroup group) {
    return group == CatalogGroup.equipment
        ? AppImages.equipmentStd
        : AppImages.machineryStd;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final group = ref.watch(browseCatalogGroupProvider);
    final session = ref.watch(currentBrowseGroupSessionProvider);
    final selected = ref.watch(selectedBrowseCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories =
        (categoriesAsync.valueOrNull?.items ?? const <Category>[])
            .where((item) => item.catalogGroup == group)
            .toList();

    final title = selected?.localizedName(languageCode) ?? l10n.allCategories;
    final description = selected == null
        ? _allCategoriesDescription(l10n, group)
        : selected.localizedDescription(languageCode);
    final imageUrl = selected?.imageUrl;
    final searchExpanded = session.searchExpanded;

    return BaseTile(
      padding: const EdgeInsets.all(AppDimens.s08$sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDimens.r10$base),
                  onTap: () => unawaited(
                    _openCategoryPicker(categories: categories, group: group),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.s04$xs,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: _imageSize,
                          height: _imageSize * 0.8,
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? OptimizedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                )
                              : _allCategoriesImage(group)(
                                  size: _imageSize,
                                  fit: BoxFit.contain,
                                ),
                        ),
                        const SizedBox(width: AppDimens.s12$md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.headingM(context),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: AppDimens.s08$sm),
                                Text(
                                  description,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.caption(context),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.s08$sm),
              Column(
                spacing: AppDimens.s04$xs,
                children: [
                  // AppIconButton(
                  //   icon: LucideIcons.funnel,
                  //   tooltip: l10n.categoryFilters,
                  //   variant: _hasActiveFilters
                  //       ? AppIconButtonVariant.soft
                  //       : AppIconButtonVariant.plain,
                  //   tone: _hasActiveFilters
                  //       ? AppIconButtonTone.primary
                  //       : AppIconButtonTone.neutral,
                  //   onTap: _openFilters,
                  // ),
                  AppIconButton(
                    icon: LucideIcons.search,
                    tooltip: l10n.search,
                    variant: searchExpanded
                        ? AppIconButtonVariant.soft
                        : AppIconButtonVariant.plain,
                    tone: searchExpanded
                        ? AppIconButtonTone.primary
                        : AppIconButtonTone.neutral,
                    onTap: _toggleSearch,
                  ),
                ],
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: searchExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppDimens.s12$md),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _searchController,
                            hint: l10n.searchEquipment,
                            textInputAction: TextInputAction.search,
                            onChanged: _setQuery,
                            onSubmitted: (value) {
                              _debounce?.cancel();
                              ref
                                  .read(browseGroupSessionsProvider.notifier)
                                  .setQuery(value);
                              _syncSearchProvider(value);
                            },
                          ),
                        ),
                        const SizedBox(width: AppDimens.s08$sm),
                        AppIconButton(
                          icon: LucideIcons.x,
                          tooltip: l10n.search,
                          onTap: () => _collapseSearch(clearQuery: true),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
