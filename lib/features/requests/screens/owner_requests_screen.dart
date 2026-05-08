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

    final requestState = ref.watch(requestProvider);
    final offersState = ref.watch(offersProvider);

    /// 🎯 Filter active requests
    final activeRequests = requestState.ownerRequests
        .where((r) => ["CREATED", "VIEWED"].contains(r.status))
        .toList();

    /// 🎯 Group offers by requestId
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
              expandedHeight: 60, // Adjust height as needed
              floating: true, // AppBar reappears immediately when scrolling up
              pinned: false, // AppBar hides completely when scrolling down
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
                "Requests",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              centerTitle: false,
            ),

            /// 🔹 Empty state
            if (requestState.isLoading)
              SliverToBoxAdapter(child: RequestTileSkeleton())
            else if (requestState.error != null)
              SliverToBoxAdapter(child: Text("Error Loading Requests"))
            else if (activeRequests.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyStateTile(title: "No Requests at the moment"),
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
