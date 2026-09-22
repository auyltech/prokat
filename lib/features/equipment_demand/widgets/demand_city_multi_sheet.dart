import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Multi-select cities for demand survey. Does not touch [locationProvider].
class DemandCityMultiSheet extends ConsumerStatefulWidget {
  final Set<String> initialSelectedIds;

  const DemandCityMultiSheet({super.key, required this.initialSelectedIds});

  static Future<List<String>?> show({
    required BuildContext context,
    required Set<String> initialSelectedIds,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppBottomSheet.show<List<String>>(
      context,
      title: l10n.demandSurveySelectCities,
      contentBuilder: (_) =>
          DemandCityMultiSheet(initialSelectedIds: initialSelectedIds),
    );
  }

  @override
  ConsumerState<DemandCityMultiSheet> createState() =>
      _DemandCityMultiSheetState();
}

class _DemandCityMultiSheetState extends ConsumerState<DemandCityMultiSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelectedIds);
  }

  void _toggle(String cityId) {
    setState(() {
      if (_selected.contains(cityId)) {
        _selected.remove(cityId);
      } else {
        _selected.add(cityId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final cities = List<CatalogCity>.from(catalog?.visibleCities ?? const [])
      ..sort((a, b) {
        final byIndex = a.sortIndex.compareTo(b.sortIndex);
        if (byIndex != 0) return byIndex;
        return a.names
            .pickPreferRu(locale, fallback: a.slug)
            .compareTo(b.names.pickPreferRu(locale, fallback: b.slug));
      });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          child: cities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppDimens.s16$base),
                  child: Text(
                    l10n.demandSurveyLoadError,
                    style: AppFonts.body14(context),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final label = city.names.pickPreferRu(
                      locale,
                      fallback: city.slug,
                    );
                    return AppCheckboxTile(
                      value: _selected.contains(city.id),
                      title: label,
                      onChanged: (_) => _toggle(city.id),
                    );
                  },
                ),
        ),
        const SizedBox(height: AppDimens.s16$base),
        AppElevatedButton(
          title: l10n.demandSurveySubmit,
          onTap: _selected.isEmpty
              ? null
              : () => context.pop(_selected.toList(growable: false)),
        ),
      ],
    );
  }
}
