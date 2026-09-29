import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/categories/state/browse_group_session.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/catalog_group_tabs.dart';
import 'package:prokat/features/categories/widgets/category_header_card.dart';

class GuestCategorySection extends ConsumerWidget {
  const GuestCategorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).valueOrNull;
    final groups = userVisibleCatalogGroups(catalog);
    final group = coerceCatalogGroup(
      ref.watch(browseCatalogGroupProvider),
      groups,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CatalogGroupTabs(
              groups: groups,
              selected: group,
              onChanged: (next) {
                ref.read(browseGroupSessionsProvider.notifier).ensure(next);
                ref.read(browseCatalogGroupProvider.notifier).select(next);
              },
            ),
          ),
          if (groups.length > 1) const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: CategoryHeaderCard(),
          ),
        ],
      ),
    );
  }
}
