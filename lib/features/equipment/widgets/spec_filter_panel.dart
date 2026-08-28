import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_facet.dart';
import 'package:prokat/features/catalog/models/catalog_spec_type.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
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
  final Map<String, Set<String>> _options = {};
  final Map<String, bool?> _booleans = {};
  String? _categoryId;

  @override
  void dispose() {
    for (final controller in [..._min.values, ..._max.values]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _publish() {
    final catalog = ref.read(catalogProvider).valueOrNull;
    if (catalog == null) {
      ref.read(specFilterQueryProvider.notifier).state = const [];
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
        encoded.add('${spec.slug}:${selected.join(',')}');
      } else if (spec.type == CatalogSpecType.boolean) {
        final value = _booleans[spec.slug];
        if (value == null) continue;
        encoded.add('${spec.slug}:${value ? 'true' : 'false'}');
      }
    }

    ref.read(specFilterQueryProvider.notifier).state = encoded;
  }

  CatalogFacet? _facetFor(List<CatalogFacet> facets, String specId) {
    for (final facet in facets) {
      if (facet.specId == specId) return facet;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final categoryId = ref.watch(selectedCategoryProvider)?.id;
    final facets =
        categoryId == null
            ? const <CatalogFacet>[]
            : (ref.watch(catalogFacetsProvider(categoryId)).valueOrNull ??
                  const <CatalogFacet>[]);

    if (_categoryId != categoryId) {
      _categoryId = categoryId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final controller in [..._min.values, ..._max.values]) {
          controller.clear();
        }
        _options.clear();
        _booleans.clear();
        ref.read(specFilterQueryProvider.notifier).state = const [];
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
          final label = spec.label(locale);
          if (spec.type == CatalogSpecType.number) {
            _min.putIfAbsent(spec.slug, TextEditingController.new);
            _max.putIfAbsent(spec.slug, TextEditingController.new);
            final unit = catalog.unitById(spec.unitId)?.symbol(locale) ?? '';
            final hintMin = facet?.min?.toString();
            final hintMax = facet?.max?.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _min[spec.slug],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '$label min',
                        hintText: hintMin,
                        suffixText: unit.isEmpty ? null : unit,
                      ),
                      onChanged: (_) => _publish(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _max[spec.slug],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '$label max',
                        hintText: hintMax,
                        suffixText: unit.isEmpty ? null : unit,
                      ),
                      onChanged: (_) => _publish(),
                    ),
                  ),
                ],
              ),
            );
          }

          if (spec.type == CatalogSpecType.select ||
              spec.type == CatalogSpecType.multiSelect) {
            final catalogOptions = catalog.optionsForSpec(spec.id);
            final facetSlugs = {
              for (final option in facet?.options ?? const <CatalogFacetOption>[])
                if (option.count > 0) option.slug,
            };
            final options = facetSlugs.isEmpty
                ? catalogOptions
                : catalogOptions
                    .where((option) => facetSlugs.contains(option.slug))
                    .toList();
            if (options.isEmpty) return const SizedBox.shrink();
            final selected = _options.putIfAbsent(spec.slug, () => <String>{});
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Wrap(
                    spacing: 8,
                    children: options.map((option) {
                      final isSelected = selected.contains(option.slug);
                      return FilterChip(
                        label: Text(option.label(locale)),
                        selected: isSelected,
                        onSelected: (next) {
                          setState(() {
                            if (next) {
                              selected.add(option.slug);
                            } else {
                              selected.remove(option.slug);
                            }
                          });
                          _publish();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          if (spec.type == CatalogSpecType.boolean) {
            final selected = _booleans[spec.slug];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Yes'),
                        selected: selected == true,
                        onSelected: (next) {
                          setState(() {
                            _booleans[spec.slug] = next ? true : null;
                          });
                          _publish();
                        },
                      ),
                      FilterChip(
                        label: const Text('No'),
                        selected: selected == false,
                        onSelected: (next) {
                          setState(() {
                            _booleans[spec.slug] = next ? false : null;
                          });
                          _publish();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
