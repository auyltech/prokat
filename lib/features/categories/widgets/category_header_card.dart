import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
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

/// Category selection and search, with quick category chips in the new flow.
///
/// Search UI is per catalog-group session (lazy + sticky across tabs).
class CategoryHeaderCard extends ConsumerStatefulWidget {
  const CategoryHeaderCard({super.key, this.group});

  /// When set, the card stays on this catalog group instead of following the
  /// active browse tab. Used by swipeable search pages.
  final CatalogGroup? group;

  @override
  ConsumerState<CategoryHeaderCard> createState() => _CategoryHeaderCardState();
}

class _CategoryHeaderCardState extends ConsumerState<CategoryHeaderCard>
    with SingleTickerProviderStateMixin {
  static const _searchRevealDuration = Duration(milliseconds: 200);

  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  late final AnimationController _searchReveal;
  final _quickCategoriesScroll = ScrollController(
    debugLabel: 'categoryHeaderQuickCategories',
  );
  Timer? _debounce;
  ProviderSubscription<CatalogGroup>? _groupSub;

  @override
  void initState() {
    super.initState();
    final sessions = ref.read(browseGroupSessionsProvider.notifier);
    final CatalogGroup group =
        widget.group ?? ref.read(browseCatalogGroupProvider);
    // Peek only — do not mutate providers during initState/build.
    final existing = sessions.peek(group);
    _searchController = TextEditingController(text: existing?.query ?? '');
    _searchFocus = FocusNode(debugLabel: 'categoryHeaderSearch');
    _searchReveal = AnimationController(
      vsync: this,
      duration: _searchRevealDuration,
      value: (existing?.searchExpanded ?? false) ? 1 : 0,
    );

    if (widget.group == null) {
      _groupSub = ref.listenManual(browseCatalogGroupProvider, (
        previous,
        next,
      ) {
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
    }

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
    _quickCategoriesScroll.dispose();
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

  void _usePinnedGroup() {
    final group = widget.group;
    if (group == null) return;
    if (ref.read(browseCatalogGroupProvider) == group) return;
    ref.read(browseGroupSessionsProvider.notifier).ensure(group);
    ref.read(browseCatalogGroupProvider.notifier).select(group);
  }

  void _setQuery(String value) {
    _usePinnedGroup();
    ref.read(browseGroupSessionsProvider.notifier).setQuery(value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _syncSearchProvider(value);
    });
  }

  void _submitQuery(String value) {
    _usePinnedGroup();
    _debounce?.cancel();
    ref.read(browseGroupSessionsProvider.notifier).setQuery(value);
    _syncSearchProvider(value);
    _clearSearchFocus();
  }

  void _clearQuery() {
    _usePinnedGroup();
    _debounce?.cancel();
    _searchController.clear();
    ref.read(browseGroupSessionsProvider.notifier).clearSearch();
    _syncSearchProvider('');
  }

  void _collapseSearch({required bool clearQuery}) {
    _usePinnedGroup();
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
    _usePinnedGroup();
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
    final selectedId = widget.group == null
        ? ref.read(selectedBrowseCategoryProvider)?.id
        : ref.read(selectedBrowseCategoryProvider.notifier).stored(group)?.id;
    final selected = await CategoryPickerSheet.show(
      context,
      categories: categories,
      group: group,
      selectedId: selectedId,
    );
    if (!mounted || selected == null) return;

    _selectCategory(selected.isAll ? null : selected.category);
  }

  void _selectCategory(Category? category) {
    _usePinnedGroup();
    _collapseSearch(clearQuery: true);
    if (category == null) {
      ref.read(selectedBrowseCategoryProvider.notifier).clear();
    } else {
      ref.read(selectedBrowseCategoryProvider.notifier).select(category);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_quickCategoriesScroll.hasClients) return;
      _quickCategoriesScroll.jumpTo(0);
    });
  }

  Category? _selectedForPinnedGroup(CatalogGroup group) {
    ref.watch(selectedBrowseCategoryProvider);
    return ref.read(selectedBrowseCategoryProvider.notifier).stored(group);
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
    final CatalogGroup group =
        widget.group ?? ref.watch(browseCatalogGroupProvider);
    final session = widget.group == null
        ? ref.watch(currentBrowseGroupSessionProvider)
        : ref.watch(browseGroupSessionsProvider)[group] ??
              const BrowseGroupSession();
    final selected = widget.group == null
        ? ref.watch(selectedBrowseCategoryProvider)
        : _selectedForPinnedGroup(group);
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
    final flow = ProkatFlowScope.maybeOf(context);

    if (flow != null) {
      final quickCategories = categories
          .take(6)
          .where((category) => category.id != selected?.id)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _FlowCategorySearch(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  palette: flow,
                  onChanged: _setQuery,
                  onSubmitted: _submitQuery,
                  onClear: _clearQuery,
                  onTapOutside: _clearSearchFocus,
                ),
              ),
              const SizedBox(width: 10),
              _FlowCategoryPickerButton(
                label: '${l10n.selectCategory}: $title',
                palette: flow,
                onTap: () => unawaited(
                  _openCategoryPicker(categories: categories, group: group),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            controller: _quickCategoriesScroll,
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                if (selected != null)
                  _FlowCategoryChip(
                    title: selected.localizedName(languageCode),
                    selected: true,
                    palette: flow,
                    onTap: () => _selectCategory(null),
                  ),
                _FlowCategoryChip(
                  title: l10n.allCategories,
                  selected: selected == null,
                  palette: flow,
                  onTap: () => _selectCategory(null),
                ),
                for (final category in quickCategories)
                  _FlowCategoryChip(
                    title: category.localizedName(languageCode),
                    selected: false,
                    palette: flow,
                    onTap: () => _selectCategory(category),
                  ),
              ],
            ),
          ),
        ],
      );
    }

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
                            onSubmitted: _submitQuery,
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

class _FlowCategoryPickerButton extends StatelessWidget {
  final String label;
  final ProkatFlowPalette palette;
  final VoidCallback onTap;

  const _FlowCategoryPickerButton({
    required this.label,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Material(
          color: palette.filledPrimary,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: const SizedBox.square(
              dimension: 56,
              child: Icon(
                LucideIcons.slidersHorizontal,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowCategoryChip extends StatelessWidget {
  final String title;
  final bool selected;
  final ProkatFlowPalette palette;
  final VoidCallback onTap;

  const _FlowCategoryChip({
    required this.title,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? palette.filledPrimary : palette.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? palette.filledPrimary : palette.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: AppFonts.body14(context).copyWith(
                  color: selected ? Colors.white : palette.title,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowCategorySearch extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ProkatFlowPalette palette;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onTapOutside;

  const _FlowCategorySearch({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: Listenable.merge([controller, focusNode]),
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: focusNode.hasFocus ? palette.primary : palette.border,
          ),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTapOutside: (_) => onTapOutside(),
          cursorColor: palette.primary,
          style: AppFonts.body16(context).copyWith(color: palette.title),
          decoration: InputDecoration(
            hintText: l10n.search,
            hintStyle: AppFonts.body16(context)
                .copyWith(color: palette.secondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            constraints: const BoxConstraints(minHeight: 56),
            prefixIcon: Icon(
              LucideIcons.search,
              size: 20,
              color: palette.secondary,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clearSearch,
                    onPressed: onClear,
                    icon: Icon(
                      LucideIcons.x,
                      size: 20,
                      color: palette.secondary,
                    ),
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),
        ),
      ),
    );
  }
}
