import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerRequestsScreen extends ConsumerStatefulWidget {
  const OwnerRequestsScreen({super.key});

  @override
  ConsumerState<OwnerRequestsScreen> createState() =>
      _OwnerRequestsScreenState();
}

class _OwnerRequestsScreenState extends ConsumerState<OwnerRequestsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(offersProvider.notifier).getOwnerOffers();
      ref.read(requestProvider.notifier).getOwnerRequests();
      ref.read(equipmentProvider.notifier).getOwnerEquipment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final requestState = ref.watch(requestProvider);
    final offersState = ref.watch(offersProvider);

    final activeRequests = requestState.ownerRequests
        .where((r) => ["CREATED", "VIEWED"].contains(r.status))
        .toList();

    final offersByRequest = <String, List<OfferModel>>{};

    for (final offer in offersState.ownerOffers) {
      if (!["CREATED", "VIEWED"].contains(offer.status)) continue;

      offersByRequest.putIfAbsent(offer.requestId, () => []);
      offersByRequest[offer.requestId]!.add(offer);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 60,
              floating: true,
              pinned: false,
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
                l10n.navRequests,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              centerTitle: false,
            ),

            if (requestState.isLoading)
              SliverToBoxAdapter(child: RequestTileSkeleton())
            else if (requestState.error != null)
              SliverToBoxAdapter(child: Text(l10n.errorLoadingRequests))
            else if (activeRequests.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyStateTile(title: l10n.noRequestsAtMoment),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final request = activeRequests[index];
                    final requestOffers = offersByRequest[request.id] ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: OwnerRequestTile(
                        request: request,
                        offers: requestOffers,
                      ),
                    );
                  }, childCount: activeRequests.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
