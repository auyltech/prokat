import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/category_card.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/category_row_skeleton.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

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
  Future<void> onCategorySelected(
    BuildContext context,
    Category category,
  ) async {
    if (widget.mode == "create_request") {
      ref.read(requestProvider.notifier).selectCategory(category);
    } else if (widget.mode == "search") {}

    ref.read(categoriesProvider.notifier).selectCategory(category);

    final userProfileState = ref.read(userProfileProvider.notifier);

    userProfileState.selectCategory(category.id);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoriesState.fetchStatus == FetchStatus.initial ||
            categoriesState.fetchStatus == FetchStatus.loading)
          const CategoryRowSkeleton()
        else if (categoriesState.fetchError != null)
          const EmptyStateTile(
            icon: LucideIcons.router,
            title: "Error Loading Services",
            subtitle: "Could not load services",
          )
        else if (categoriesState.categories.isEmpty)
          const EmptyStateTile(
            title: "No services found",
            subtitle: "There are no services listed at the moment",
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categoriesState.categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = categoriesState.categories[index];
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
