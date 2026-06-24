import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/features/categories/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: BaseTile(
        width: 140,
        borderColor: isSelected ? theme.primaryColor : null,
        child: Column(
          children: [
            Expanded(
              child:
                  (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                  ? Image.network(
                      category.imageUrl!,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? theme.primaryColor
                    : theme.textTheme.bodyMedium?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
