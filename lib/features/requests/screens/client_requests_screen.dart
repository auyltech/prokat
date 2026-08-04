import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(clientActiveRequestsProvider.notifier).loadMore();
        ref
            .read(clientOffersProvider(const OfferQuery.active()).notifier)
            .loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientActiveRequestsProvider.notifier).refreshIfStale();

      ref
          .read(clientOffersProvider(const OfferQuery.active()).notifier)
          .refreshIfStale();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final requestsAsync = ref.watch(clientActiveRequestsProvider);
    final offersAsync = ref.watch(
      clientOffersProvider(const OfferQuery.active()),
    );

    final offers = (offersAsync.valueOrNull?.items ?? const []).where(
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
          await Future.wait([
            ref.read(clientActiveRequestsProvider.notifier).refresh(),
            ref
                .read(clientOffersProvider(const OfferQuery.active()).notifier)
                .refresh(),
          ]);
        },
        child: requestsAsync.when(
          loading: () => const RequestTileSkeleton(),

          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              EmptyStateTile(
                imageName: 'empty_error.png',
                title: l10n.errorLoadingRequests,
                subtitle: error.toString(),
              ),
            ],
          ),

          data: (query) {
            final requests = query.items;

            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (requests.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: EmptyStateTile(
                      imageName: 'empty_requests.png',
                      title: l10n.noRequestsAtMoment,
                      subtitle: l10n.noActiveRequests,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.7),
                    ),
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      final requestOffers = offersByRequest[r.id] ?? [];
                      return RequestWithOffers(
                        request: r,
                        offers: requestOffers,
                        onCancel: () => ref
                            .read(requestMutationProvider.notifier)
                            .cancelRequest(r.id),
                      );
                    },
                  ),

                if (query.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (!query.hasMore && requests.isNotEmpty)
                  const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
