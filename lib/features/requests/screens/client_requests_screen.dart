import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/features/requests/widgets.dart/request_with_offers.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientRequestsScreen extends ConsumerStatefulWidget {
  const ClientRequestsScreen({super.key});

  @override
  ConsumerState<ClientRequestsScreen> createState() =>
      _ClientRequestsScreenState();
}

class _ClientRequestsScreenState extends ConsumerState<ClientRequestsScreen> {
  Future<void> fetchData() async {
    final state = ref.read(requestProvider);

    if (state.lastFetchedAt != null) {
      final age = DateTime.now().difference(state.lastFetchedAt!);

      if (age.inMinutes >= 1) {
        await ref.read(requestProvider.notifier).getClientRequests();
      }
    }

    await ref.read(offersProvider.notifier).getClientOffers();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final requestsState = ref.watch(requestProvider);
    final offersState = ref.watch(offersProvider);

    final activeRequests = ref
        .watch(requestProvider.notifier)
        .getActiveRequests(AppMode.clientMode);

    final offers = offersState.renterOffers.where(
      (r) => [OfferStatus.created, OfferStatus.viewed].contains(r.status),
    );

    final offersByRequest = <String, List<dynamic>>{};

    for (final offer in offers) {
      final requestId = offer.requestId;

      if (!offersByRequest.containsKey(requestId)) {
        offersByRequest[requestId] = [];
      }

      offersByRequest[requestId]!.add(offer);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          fetchData();
        },
        child: ListView(
          children: [
            if (requestsState.fetchStatus == FetchStatus.loading ||
                (requestsState.fetchStatus == FetchStatus.refreshing &&
                    activeRequests.isEmpty))
              RequestTileSkeleton()
            else if (requestsState.fetchStatus == FetchStatus.error)
              EmptyStateTile(
                icon: Icons.error_outline,
                title: l10n.errorLoadingRequests,
                subtitle: requestsState.fetchError?.message,
              )
            else if (requestsState.fetchStatus == FetchStatus.empty ||
                (requestsState.fetchStatus == FetchStatus.success &&
                    activeRequests.isEmpty))
              EmptyStateTile(
                icon: Icons.inventory_2_outlined,
                title: l10n.noRequestsAtMoment,
                subtitle: "You don't have any active requests at the moment",
              )
            else
              ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor.withValues(alpha: 0.7),
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeRequests.length,
                itemBuilder: (context, index) {
                  final r = activeRequests[index];
                  final requestOffers = offersByRequest[r.id] ?? [];
                  return RequestWithOffers(
                    request: r,
                    offers: requestOffers,
                    onCancel: () =>
                        ref.read(requestProvider.notifier).cancelRequest(r.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
