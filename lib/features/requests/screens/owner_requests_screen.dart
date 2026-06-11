import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_tile.dart';
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

    Future.microtask(() async {
      await ref.read(offersProvider.notifier).getOwnerOffers();
      await ref.read(requestProvider.notifier).getOwnerRequests();
      await ref.read(equipmentProvider.notifier).getOwnerEquipment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final requestState = ref.watch(requestProvider);
    final offersState = ref.watch(offersProvider);

    final activeRequests = ref.watch(
      requestProvider.select((notifier) => notifier.activeOwnerRequests),
    );

    final offersByRequest = <String, List<OfferModel>>{};

    for (final offer in offersState.ownerOffers) {
      if (![OfferStatus.created].contains(offer.status)) continue;

      offersByRequest.putIfAbsent(offer.requestId, () => []);
      offersByRequest[offer.requestId]!.add(offer);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(offersProvider.notifier).getOwnerOffers();
          await ref.read(requestProvider.notifier).getOwnerRequests();
        },
        child: ListView(
          children: [
            if (requestState.isLoading)
              RequestTileSkeleton()
            else if (requestState.error != null)
              Text(l10n.errorLoadingRequests)
            else if (activeRequests.isEmpty)
              EmptyStateTile(title: l10n.noRequestsAtMoment)
            else
              ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeRequests.length,
                itemBuilder: (context, index) {
                  return OwnerRequestTile(
                    request: activeRequests[index],
                    offers: offersByRequest[activeRequests[index].id] ?? [],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
