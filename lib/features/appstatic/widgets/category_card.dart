import 'package:flutter/material.dart';
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
      child: SizedBox(
        width: 140,
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
                    ? theme.colorScheme.primary
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

class DemandCategoryCard extends StatelessWidget {
  final VoidCallback onTap;
  final String title;

  const DemandCategoryCard({super.key, required this.onTap, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 140,
            child: Column(
              children: [
                Expanded(child: Stack(alignment: Alignment.center, children: [Icon(Icons.agriculture_outlined, size: 52, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.25)), Text('?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))])),
                const SizedBox(height: 4),
                Text(title, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
