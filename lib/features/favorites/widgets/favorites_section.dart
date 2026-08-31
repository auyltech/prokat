import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_link_button.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/favorites/widgets/favorite_item_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class FavoritesOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const FavoritesOverlay({super.key, required this.child});

  static const collapsedHeight = 56.0;
  static const listPaddingTop = 12.0;
  static const listPaddingBottom = 16.0;
  static const cardListHeight = 200.0;
  static const expandedHeight =
      collapsedHeight + listPaddingTop + cardListHeight + listPaddingBottom;
  static const animationDuration = Duration(milliseconds: 300);
  static const animationCurve = Curves.easeInOutCubic;

  @override
  ConsumerState<FavoritesOverlay> createState() => _FavoritesOverlayState();
}

class _FavoritesOverlayState extends ConsumerState<FavoritesOverlay> {
  bool _expanded = false;
  ProviderSubscription? _favoritesSub;

  @override
  void initState() {
    super.initState();
    _favoritesSub = ref.listenManual(
      favoritesProvider.select((s) => s.favorites?.isNotEmpty ?? false),
      (previous, hasItems) {
        if (!hasItems && _expanded) {
          setState(() => _expanded = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _favoritesSub?.close();
    super.dispose();
  }

  void _collapse() {
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  bool _onCatalogScroll(ScrollNotification notification) {
    if (!_expanded) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _collapse();
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _collapse();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final hasFavorites = ref.watch(
      favoritesProvider.select((s) => s.favorites?.isNotEmpty ?? false),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: AnimatedPadding(
            duration: FavoritesOverlay.animationDuration,
            curve: FavoritesOverlay.animationCurve,
            padding: EdgeInsets.only(
              bottom: hasFavorites ? FavoritesOverlay.collapsedHeight : 0,
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: _onCatalogScroll,
              child: Listener(
                onPointerDown: (_) => _collapse(),
                child: widget.child,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: FavoritesSection(expanded: _expanded, onHeaderTap: _toggle),
        ),
      ],
    );
  }
}

class FavoritesSection extends ConsumerWidget {
  final bool expanded;
  final VoidCallback onHeaderTap;

  const FavoritesSection({
    super.key,
    required this.expanded,
    required this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final favorites = ref.watch(favoritesProvider).favorites ?? const [];

    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = expanded
        ? FavoritesOverlay.expandedHeight
        : FavoritesOverlay.collapsedHeight;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.hardEdge,
      child: AnimatedContainer(
        key: const Key('favorites-section-drawer'),
        duration: FavoritesOverlay.animationDuration,
        curve: FavoritesOverlay.animationCurve,
        height: height,
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(
              height: FavoritesOverlay.collapsedHeight,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          key: const Key('favorites-section-header'),
                          onTap: onHeaderTap,
                          child: SizedBox.expand(
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: expanded ? 0.5 : 0,
                                  duration: FavoritesOverlay.animationDuration,
                                  curve: FavoritesOverlay.animationCurve,
                                  child: Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: theme.colorScheme.onSurface,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          l10n.myFavorites,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _FavoritesCountBadge(
                                        count: favorites.length,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AppLinkButton(
                        label: l10n.viewAll,
                        onTap: () => context.push(AppRoutes.favorites),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight:
                      FavoritesOverlay.expandedHeight -
                      FavoritesOverlay.collapsedHeight,
                  maxHeight:
                      FavoritesOverlay.expandedHeight -
                      FavoritesOverlay.collapsedHeight,
                  child: Stack(
                    children: [
                      IgnorePointer(
                        ignoring: !expanded,
                        child: _FavoritesStrip(favorites: favorites),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: FavoritesOverlay.animationDuration,
                            curve: FavoritesOverlay.animationCurve,
                            opacity: expanded ? 1 : 0,
                            child: const _WellShadows(),
                          ),
                        ),
                      ),
                    ],
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

class _FavoritesCountBadge extends StatelessWidget {
  final int count;

  const _FavoritesCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final overflows = count > 9;

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.red, size: 30),
          Text(
            overflows ? '9+' : '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: overflows ? 11 : 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellShadows extends StatelessWidget {
  const _WellShadows();

  @override
  Widget build(BuildContext context) {
    const shadow = Colors.black;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 14,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  shadow.withValues(alpha: 0.10),
                  shadow.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  shadow.withValues(alpha: 0.06),
                  shadow.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesStrip extends StatelessWidget {
  final List<Equipment> favorites;

  const _FavoritesStrip({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: FavoritesOverlay.listPaddingTop,
        bottom: FavoritesOverlay.listPaddingBottom,
      ),
      child: SizedBox(
        height: FavoritesOverlay.cardListHeight,
        child: ListView.separated(
          key: const Key('favorites-section-list'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: favorites.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return FavoriteItemTile(equipment: favorites[index]);
          },
        ),
      ),
    );
  }
}
