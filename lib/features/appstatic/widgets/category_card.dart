import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/categories/models/category.dart';

TextStyle _categoryTileLabelStyle(ThemeData theme, {bool selected = false}) {
  return TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: 0,
    color: selected
        ? theme.colorScheme.primary
        : theme.textTheme.bodyMedium?.color,
  );
}

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
      child: Column(
        children: [
          Expanded(
            child: (category.imageUrl != null && category.imageUrl!.isNotEmpty)
                ? OptimizedNetworkImage(
                    imageUrl: category.imageUrl,
                    height: 50,
                    fit: BoxFit.contain,
                  )
                : const Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
                  ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: Text(
              category.localizedName(
                Localizations.localeOf(context).languageCode,
              ),
              style: _categoryTileLabelStyle(theme, selected: isSelected),
              maxLines: 2,
              overflow: TextOverflow.clip,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class DemandCategoryCard extends StatelessWidget {
  final VoidCallback onTap;
  final String title;

  const DemandCategoryCard({
    super.key,
    required this.onTap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: ClipRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox.expand(),
                    Positioned(
                      top: -6,
                      child: Icon(
                        Icons.agriculture_outlined,
                        size: 110,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    ),
                    Text(
                      '?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 60,
                        height: 1,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: Text(
                title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.clip,
                softWrap: true,
                style: _categoryTileLabelStyle(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
