import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/catalog_facet.dart';
import 'package:prokat/features/catalog/models/catalog_spec_type.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/equipment/widgets/spec_filter_field.dart';
import 'package:prokat/features/equipment/widgets/spec_option_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

final specFilterQueryProvider = StateProvider<List<String>>((ref) => const []);

class SpecFilterPanel extends ConsumerStatefulWidget {
  const SpecFilterPanel({super.key});

  @override
  ConsumerState<SpecFilterPanel> createState() => _SpecFilterPanelState();
}

class _SpecFilterPanelState extends ConsumerState<SpecFilterPanel> {
  final Map<String, TextEditingController> _min = {};
  final Map<String, TextEditingController> _max = {};
  final Map<String, TextEditingController> _text = {};
  final Map<String, Set<String>> _options = {};
  final Map<String, bool?> _booleans = {};
  String? _categoryId;

  @override
  void dispose() {
    for (final controller in [
      ..._min.values,
      ..._max.values,
      ..._text.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _publish() {
    final catalog = ref.read(catalogProvider).valueOrNull;
    if (catalog == null) {
      _setQuery(const []);
      return;
    }

    final encoded = <String>[];
    for (final binding in catalog.filterBindingsForCategory(_categoryId)) {
      final spec = catalog.specById(binding.specId);
      if (spec == null || !spec.type.isKnown) continue;
      if (spec.type == CatalogSpecType.select &&
          catalog.optionsForSpec(spec.id).isEmpty) {
        continue;
      }

      if (spec.type == CatalogSpecType.number) {
        final min = _min[spec.slug]?.text.trim() ?? '';
        final max = _max[spec.slug]?.text.trim() ?? '';
        if (min.isEmpty && max.isEmpty) continue;
        encoded.add('${spec.slug}:$min..$max');
      } else if (spec.type == CatalogSpecType.select ||
          spec.type == CatalogSpecType.multiSelect) {
        final selected = _options[spec.slug] ?? {};
        if (selected.isEmpty) continue;
        final slugs = selected.toList()..sort();
        encoded.add('${spec.slug}:${slugs.join(',')}');
      } else if (spec.type == CatalogSpecType.boolean) {
        final value = _booleans[spec.slug];
        if (value == null) continue;
        encoded.add('${spec.slug}:${value ? 'true' : 'false'}');
      } else if (spec.type == CatalogSpecType.string) {
        final value = _text[spec.slug]?.text.trim() ?? '';
        if (value.isEmpty) continue;
        encoded.add('${spec.slug}:$value');
      }
    }

    _setQuery(encoded);
  }

  void _setQuery(List<String> encoded) {
    final current = ref.read(specFilterQueryProvider);
    if (listEquals(current, encoded)) return;
    ref.read(specFilterQueryProvider.notifier).state = encoded;
  }

  void _resetFilters() {
    for (final controller in [
      ..._min.values,
      ..._max.values,
      ..._text.values,
    ]) {
      controller.clear();
    }
    _options.clear();
    _booleans.clear();
    _setQuery(const []);
  }

  CatalogFacet? _facetFor(List<CatalogFacet> facets, String specId) {
    for (final facet in facets) {
      if (facet.specId == specId) return facet;
    }
    return null;
  }

  String _labelWithUnit(String name, String unit) {
    if (unit.isEmpty) return name;
    return '$name, $unit';
  }

  String? _facetHint(double? value) {
    if (value == null) return null;
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  List<CatalogSpecOption> _visibleOptions({
    required List<CatalogSpecOption> catalogOptions,
    required CatalogFacet? facet,
    required Set<String> selected,
  }) {
    final facetSlugs = {
      for (final option in facet?.options ?? const <CatalogFacetOption>[])
        if (option.count > 0) option.slug,
    };
    if (facetSlugs.isEmpty) return catalogOptions;
    return catalogOptions
        .where(
          (option) =>
              facetSlugs.contains(option.slug) ||
              selected.contains(option.slug),
        )
        .toList();
  }

  String _selectedLabels(
    List<CatalogSpecOption> options,
    Set<String> selected,
    String locale,
  ) {
    return options
        .where((option) => selected.contains(option.slug))
        .map((option) => option.label(locale))
        .join(', ');
  }

  TextInputType _numberKeyboard(CatalogSpec spec) {
    return spec.decimals == 0
        ? TextInputType.number
        : const TextInputType.numberWithOptions(decimal: true);
  }

  List<TextInputFormatter> _numberFormatters(CatalogSpec spec) {
    if (spec.decimals == 0) {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
  }

  Future<void> _openSelect({
    required String title,
    required String slug,
    required List<SpecFilterChoice> choices,
    required bool multi,
  }) async {
    final selected = _options.putIfAbsent(slug, () => <String>{});

    if (multi) {
      final result = await SpecMultiSelectSheet.show(
        context: context,
        title: title,
        options: choices,
        selected: selected,
      );
      if (!mounted || result == null) return;
      setState(() {
        selected
          ..clear()
          ..addAll(result);
      });
      _publish();
      return;
    }

    final result = await SpecSelectSheet.show(
      context: context,
      title: title,
      options: choices,
      selectedValue: selected.firstOrNull,
    );
    if (!mounted || result == null) return;
    setState(() {
      selected
        ..clear()
        ..add(result);
    });
    _publish();
  }

  Future<void> _openBoolean(String title, String slug) async {
    final l10n = AppLocalizations.of(context)!;
    final current = _booleans[slug];
    final result = await SpecSelectSheet.show(
      context: context,
      title: title,
      options: [
        SpecFilterChoice(value: 'true', label: l10n.yes),
        SpecFilterChoice(value: 'false', label: l10n.no),
      ],
      selectedValue: current == null ? null : (current ? 'true' : 'false'),
    );
    if (!mounted || result == null) return;
    setState(() => _booleans[slug] = result == 'true');
    _publish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final categoryId = ref.watch(selectedCategoryProvider)?.id;
    final facets = categoryId == null
        ? const <CatalogFacet>[]
        : (ref.watch(catalogFacetsProvider(categoryId)).valueOrNull ??
              const <CatalogFacet>[]);

    if (_categoryId != categoryId) {
      _categoryId = categoryId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resetFilters();
        setState(() {});
      });
    }

    if (catalog == null || categoryId == null) {
      return const SizedBox.shrink();
    }

    final bindings = catalog.filterBindingsForCategory(categoryId);
    if (bindings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.search, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...bindings.map((binding) {
          final spec = catalog.specById(binding.specId);
          if (spec == null || !spec.type.isKnown) {
            return const SizedBox.shrink();
          }
          final facet = _facetFor(facets, spec.id);
          final name = spec.label(locale);
          final unit = catalog.unitById(spec.unitId)?.symbol(locale) ?? '';
          final label = _labelWithUnit(name, unit);

          if (spec.type == CatalogSpecType.number) {
            final minController = _min.putIfAbsent(
              spec.slug,
              TextEditingController.new,
            );
            final maxController = _max.putIfAbsent(
              spec.slug,
              TextEditingController.new,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SpecFilterField(
                      label: label,
                      hintText: _facetHint(facet?.min) ?? l10n.specFilterFrom,
                      controller: minController,
                      keyboardType: _numberKeyboard(spec),
                      inputFormatters: _numberFormatters(spec),
                      onChanged: (_) => _publish(),
                      onCleared: () {
                        minController.clear();
                        _publish();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SpecFilterField(
                      label: label,
                      hintText: _facetHint(facet?.max) ?? l10n.specFilterTo,
                      controller: maxController,
                      keyboardType: _numberKeyboard(spec),
                      inputFormatters: _numberFormatters(spec),
                      onChanged: (_) => _publish(),
                      onCleared: () {
                        maxController.clear();
                        _publish();
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          if (spec.type == CatalogSpecType.string) {
            final controller = _text.putIfAbsent(
              spec.slug,
              TextEditingController.new,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SpecFilterField(
                label: label,
                controller: controller,
                keyboardType: TextInputType.text,
                maxLength: spec.maxLength,
                inputFormatters: spec.maxLength == null
                    ? null
                    : [LengthLimitingTextInputFormatter(spec.maxLength)],
                onChanged: (_) => _publish(),
                onCleared: () {
                  controller.clear();
                  _publish();
                },
              ),
            );
          }

          if (spec.type == CatalogSpecType.select ||
              spec.type == CatalogSpecType.multiSelect) {
            final catalogOptions = catalog.optionsForSpec(spec.id);
            final selected = _options.putIfAbsent(spec.slug, () => <String>{});
            final options = _visibleOptions(
              catalogOptions: catalogOptions,
              facet: facet,
              selected: selected,
            );
            if (options.isEmpty) return const SizedBox.shrink();
            final multi = spec.type == CatalogSpecType.multiSelect;
            final choices = [
              for (final option in options)
                SpecFilterChoice(
                  value: option.slug,
                  label: option.label(locale),
                ),
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SpecFilterField(
                label: label,
                displayText: _selectedLabels(catalogOptions, selected, locale),
                onTap: () => _openSelect(
                  title: label,
                  slug: spec.slug,
                  choices: choices,
                  multi: multi,
                ),
                onCleared: () {
                  setState(() => selected.clear());
                  _publish();
                },
              ),
            );
          }

          if (spec.type == CatalogSpecType.boolean) {
            final selected = _booleans[spec.slug];
            final display = selected == null
                ? ''
                : (selected ? l10n.yes : l10n.no);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SpecFilterField(
                label: label,
                displayText: display,
                onTap: () => _openBoolean(label, spec.slug),
                onCleared: () {
                  setState(() => _booleans[spec.slug] = null);
                  _publish();
                },
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
