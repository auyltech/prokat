import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserCategorySelector extends ConsumerStatefulWidget {
  final String mode;
  final String? selectedCategoryId;

  const UserCategorySelector({
    super.key,
    required this.mode,
    this.selectedCategoryId,
  });

  @override
  ConsumerState<UserCategorySelector> createState() =>
      _UserCategorySelectorState();
}

class _UserCategorySelectorState extends ConsumerState<UserCategorySelector> {
  // Handle submit
  void onCategorySelected(BuildContext context, Category category) {
    if (widget.mode == "create_request") {
      ref.read(requestMutationProvider.notifier).selectCategory(category);
      return;
    }

    if (widget.mode == "search") {
      ref.read(selectedCategoryProvider.notifier).select(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull?.items ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoriesAsync.isLoading && categories.isEmpty)
          const CategoryRowSkeleton()
        else if (categoriesAsync.hasError && categories.isEmpty)
          EmptyStateTile(
            icon: LucideIcons.router,
            title: l10n.errorLoadingServices,
            subtitle: l10n.couldNotLoadServices,
          )
        else if (categories.isEmpty)
          EmptyStateTile(
            title: l10n.noServicesFound,
            subtitle: l10n.noServicesAvailable,
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = widget.selectedCategoryId == cat.id;

                return CategoryCard(
                  category: cat,
                  onTap: () => onCategorySelected(context, cat),
                  isSelected: isSelected,
                );
              },
            ),
          ),
      ],
    );
  }
}
