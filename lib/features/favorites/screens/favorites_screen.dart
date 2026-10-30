import 'package:prokat/features/company_profile/company_catalog_screen.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
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
              EmptyStateTile(
                title: l10n.somethingWentWrong,
                subtitle: l10n.loadContentRetryHint,
                imageName: 'empty_error.png',
              )
            else if (favorites.isEmpty)
              EmptyStateTile(
                title: l10n.noSavedMachinery,
                subtitle: l10n.favoritesEmptyHint,
                imageName: 'empty_favorites.png',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: favorites.length,
                separatorBuilder: (context, index) =>
                    ProkatFlowScope.maybeOf(context) == null
                    ? const Divider()
                    : const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = favorites[index];
                  return _FavoriteCard(
                    equipment: item,
                    onTap: () {
                      if (item.companyId != null) {
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => ClientCompanyDetailsScreen(
                              companyId: item.companyId!,
                            ),
                          ),
                        );
                        return;
                      }
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
    final flow = ProkatFlowScope.maybeOf(context);
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
          color: flow?.surface ?? theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: flow?.border ?? Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              child: OptimizedNetworkImage(
                imageUrl: equipment.imageUrl ?? "",
                height: 100,
                width: flow == null ? 130 : 88,
                fit: BoxFit.cover,
                fallbackIcon: LucideIcons.truck,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: flow == null ? null : FontWeight.w700,
                    ),
                  ),
                  UserInfoTile(user: equipment.owner),
                  const SizedBox(height: 4),
                  Text(
                    priceLabel,
                    maxLines: flow == null ? 1 : null,
                    overflow: flow == null
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
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
                  LucideIcons.chevronRight,
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
