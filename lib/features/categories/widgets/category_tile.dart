import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:go_router/go_router.dart';

class CategoryTile extends ConsumerStatefulWidget {
  final Category cat;
  final bool isSelected;

  const CategoryTile({super.key, required this.cat, required this.isSelected});

  @override
  ConsumerState<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends ConsumerState<CategoryTile> {
  Future<void> onCategorySelected(
    BuildContext context,
    Category category,
  ) async {
    ref.read(categoriesProvider.notifier).selectCategory(category);
    final userProfileState = ref.read(userProfileProvider.notifier);

    await userProfileState.selectCategory(category.id);

    if (context.mounted) {
      final uri = Uri(
        path: AppRoutes.searchList,
        queryParameters: {'category': category.id},
      ).toString();
      context.push(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onCategorySelected(context, widget.cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 130, // Square-ish look is trendier than long rectangles
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.cardColor,
          border: Border.all(
            color: widget.isSelected ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: widget.isSelected
          //         ? theme.primaryColor.withValues(alpha: 0.2)
          //         : Colors.black.withValues(alpha: 0.04),
          //     blurRadius: 10,
          //     offset: const Offset(0, 4),
          //   ),
          // ],
        ),
        child: Stack(
          children: [
            // 1. Background Image (Lower opacity or contained)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child:
                      (widget.cat.imageUrl != null &&
                          widget.cat.imageUrl!.isNotEmpty)
                      ? Image.network(
                          widget.cat.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _fallbackImage(theme),
                        )
                      : _fallbackImage(theme),
                ),
              ),
            ),

            // 3. Label Text
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  widget.cat.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: widget.isSelected ? theme.primaryColor : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _fallbackImage(ThemeData theme) {
  return Container(
    color: theme.colorScheme.surface,
    alignment: Alignment.center,
    child: Icon(
      Icons.image_not_supported_outlined,
      size: 28,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
    ),
  );
}
