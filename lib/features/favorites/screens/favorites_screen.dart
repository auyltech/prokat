import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(favoriteProvider.notifier).getFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authSession = ref.watch(authProvider).session;
    final favoritesState = ref.watch(favoriteProvider);
    final bookingNotifier = ref.read(bookingProvider.notifier);

    final favorites = favoritesState.favorites;

    final isLoading = favoritesState.isLoading;
    final error = favoritesState.error;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 60,
              floating: true,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                l10n.navFavorites,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),

            if (authSession == null)
              _buildCenteredFallback(
                icon: Icons.login_outlined,
                message: l10n.loginToAddFavorites,
              )
            else if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              _buildCenteredFallback(
                icon: Icons.error_outline,
                message: "${l10n.error}: ${favoritesState.error}",
              )
            else if (favorites != null && favorites.isEmpty)
              SliverToBoxAdapter(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.noSavedMachinery,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => context.go('/search/map'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                        side: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        l10n.exploreFleet,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = favorites?[index];
                  if (item != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FavoriteCard(
                        equipment: item,
                        onTap: () {
                          bookingNotifier.selectEquipment(item);
                          context.push('/equipment/${item.id}/book');
                        },
                      ),
                    );
                  } else {
                    return null;
                  }
                }, childCount: favorites?.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCenteredFallback({
  required IconData icon,
  required String message,
}) {
  return SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    ),
  );
}

class _FavoriteCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const _FavoriteCard({required this.equipment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final location = equipment.location != null
        ? "${equipment.location?.city}"
        : l10n.unknownLocation;

    final price = equipment.prices.isNotEmpty
        ? "${equipment.prices.first.price} ₸/${equipment.prices.first.priceRate}"
        : l10n.noPrice;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              child: OptimizedNetworkImage(
                imageUrl: equipment.imageUrl ?? "",
                height: 90,
                width: 120,
                fit: BoxFit.cover,
                fallbackIcon: Icons.precision_manufacturing_outlined,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.name, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    "$location • $price",
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
