import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// App bar title of the catalog screen. One visible catalog group is named in
/// the title; both groups keep «Каталог» and continue it on the tab bar.
class SearchBrowseTitle extends ConsumerWidget {
  const SearchBrowseTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(catalogProvider);
    if (!catalog.hasValue) return const SizedBox.shrink();

    final groups = userVisibleCatalogGroups(catalog.value);
    if (groups.length > 1) return Text(l10n.navCatalog);

    final group = groups.isEmpty ? CatalogGroup.machinery : groups.single;
    return Text(switch (group) {
      CatalogGroup.machinery => l10n.catalogMachinery,
      CatalogGroup.equipment => l10n.catalogEquipment,
    });
  }
}
