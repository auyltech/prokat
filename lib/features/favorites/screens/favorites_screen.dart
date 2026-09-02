import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
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

    unawaited(
      Future.microtask(() {
        unawaited(ref.read(favoritesProvider.notifier).getFavorites());
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final favoritesState = ref.watch(favoritesProvider);

    final favorites = favoritesState.favorites ?? [];

    final isLoading = favoritesState.isLoading;
    final error = favoritesState.error;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          children: [
            if (isLoading && favorites.isEmpty)
              EmptyStateTile(title: l10n.loading)
            else if (error != null)
              EmptyStateTile(title: l10n.somethingWentWrong)
            else if (favorites.isEmpty)
              EmptyStateTile(
                title: l10n.noSavedMachinery,
                icon: Icons.bookmark_border_rounded,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: favorites.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = favorites[index];
                  return _FavoriteCard(
                    equipment: item,
                    onTap: () {
                      ref
                          .read(bookingMutationProvider.notifier)
                          .selectEquipment(item);
                      unawaited(
                        context.push(
                          '${AppRoutes.equipment}/${item.id}/${AppRoutes.book}',
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onTap;

  const _FavoriteCard({required this.equipment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final priceEntry = equipment.prices.isNotEmpty
        ? equipment.prices.first
        : null;
    final priceLabel = priceEntry == null
        ? l10n.noPrice
        : '${formatPrice(priceEntry.price)} ${getPriceRate(priceEntry.priceRate, l10n: l10n)}'
              .trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              child: OptimizedNetworkImage(
                imageUrl: equipment.imageUrl ?? "",
                height: 100,
                width: 130,
                fit: BoxFit.cover,
                fallbackIcon: Icons.precision_manufacturing_outlined,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(equipment.name, style: theme.textTheme.bodyMedium),
                  UserInfoTile(user: equipment.owner),
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 100,
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
