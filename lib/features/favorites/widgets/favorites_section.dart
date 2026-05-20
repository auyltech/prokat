import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_link_button.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/favorites/widgets/favorite_item_tile.dart';

class FavoritesSection extends ConsumerWidget {
  const FavoritesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(favoriteProvider).favorites;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.myFavorites,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (favorites?.isNotEmpty == true)
              AppLinkButton(
                label: l10n.viewAll,
                onTap: () => context.push(AppRoutes.favorites),
              ),
          ],
        ),

        const SizedBox(height: 12),

        if (favorites?.isEmpty == true)
          _buildEmptyFavorites(theme, l10n)
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: favorites?.length,
              itemBuilder: (context, index) {
                final item = favorites?[index];
                if (item == null) {
                  return null;
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FavoriteItemTile(equipment: item),
                  );
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyFavorites(ThemeData theme, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite_border,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.favoritesEmptyHint,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
