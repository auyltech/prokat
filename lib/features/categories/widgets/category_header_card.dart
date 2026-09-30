import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/app_category_info.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_image.dart';
import 'package:prokat/features/categories/widgets/category_picker_sheet.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Expandable category header: image + title/description + search.
///
/// Search UI is per catalog-group session (lazy + sticky across tabs).
/// Filter modal is a stub until catalog filters ship.
class CategoryHeaderCard extends ConsumerStatefulWidget {
  const CategoryHeaderCard({super.key});

  @override
  ConsumerState<CategoryHeaderCard> createState() => _CategoryHeaderCardState();
}

class _CategoryHeaderCardState extends ConsumerState<CategoryHeaderCard>
    with SingleTickerProviderStateMixin {
  static const _searchRevealDuration = Duration(milliseconds: 200);

  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  late final AnimationController _searchReveal;
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
    _searchFocus = FocusNode(debugLabel: 'categoryHeaderSearch');
    _searchReveal = AnimationController(
      vsync: this,
      duration: _searchRevealDuration,
      value: (existing?.searchExpanded ?? false) ? 1 : 0,
    );

    _groupSub = ref.listenManual(browseCatalogGroupProvider, (previous, next) {
      if (previous == next) return;
      final restored = sessions.ensure(next);
      _debounce?.cancel();
      _clearSearchFocus();
      _searchController.value = TextEditingValue(
        text: restored.query,
        selection: TextSelection.collapsed(offset: restored.query.length),
      );
      _syncSearchProvider(restored.query);
      _searchReveal.value = restored.searchExpanded ? 1 : 0;
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
      _searchReveal.value = session.searchExpanded ? 1 : 0;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _groupSub?.close();
    _searchReveal.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearchFocus() {
    if (_searchFocus.hasFocus) {
      _searchFocus.unfocus();
    }
    FocusManager.instance.primaryFocus?.unfocus();
  }

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
    _clearSearchFocus();
    final sessions = ref.read(browseGroupSessionsProvider.notifier);
    if (clearQuery) {
      _searchController.clear();
      sessions.clearSearch();
      _syncSearchProvider('');
    } else {
      sessions.setSearchExpanded(false);
    }
    unawaited(_searchReveal.reverse());
    setState(() {});
  }

  void _toggleSearch() {
    final sessions = ref.read(browseGroupSessionsProvider.notifier);
    final session = sessions.forCurrentGroup();
    if (session.searchExpanded) {
      _collapseSearch(clearQuery: true);
      return;
    }
    _clearSearchFocus();
    sessions.setSearchExpanded(true);
    unawaited(_searchReveal.forward());
    setState(() {});
  }

  Future<void> _openCategoryPicker({
    required List<Category> categories,
    required CatalogGroup group,
  }) async {
    _clearSearchFocus();
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

    return AppCard(
      onTap: () =>
          unawaited(_openCategoryPicker(categories: categories, group: group)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCategoryInfo(
            title: title,
            description: description,
            imageUrl: imageUrl,
            fallbackImage: group.stdImage,
          ),
          const SizedBox(height: AppDimens.s08$sm),
          // Fixed to inputHeight so 46px field vs 44px icon buttons don't
          // bump the card when search expands.
          SizedBox(
            height: AppDimens.inputHeight,
            child: Row(
              spacing: AppDimens.s04$xs,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedBuilder(
                        animation: _searchReveal,
                        builder: (context, child) {
                          final t = Curves.linear.transform(
                            _searchReveal.value,
                          );
                          return Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: constraints.maxWidth * t,
                              height: AppDimens.inputHeight,
                              child: ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.centerRight,
                                  minWidth: constraints.maxWidth,
                                  maxWidth: constraints.maxWidth,
                                  minHeight: AppDimens.inputHeight,
                                  maxHeight: AppDimens.inputHeight,
                                  child: IgnorePointer(
                                    ignoring: t < 1,
                                    child: child,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        child: TapRegion(
                          onTapOutside: (_) => _clearSearchFocus(),
                          child: AppTextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            hint: l10n.searchEquipment,
                            textInputAction: TextInputAction.search,
                            onChanged: _setQuery,
                            onSubmitted: (value) {
                              _debounce?.cancel();
                              ref
                                  .read(browseGroupSessionsProvider.notifier)
                                  .setQuery(value);
                              _syncSearchProvider(value);
                              _clearSearchFocus();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
                // Filters stub kept out of the tree until catalog filters ship.
              ],
            ),
          ),
        ],
      ),
    );
  }
}
