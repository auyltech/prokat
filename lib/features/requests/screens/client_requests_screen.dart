import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/empty_state_artwork.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
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
  bool _loadingAllOffers = false;

  Future<void> _loadAllOffers() async {
    if (_loadingAllOffers) return;
    setState(() => _loadingAllOffers = true);
    final provider = clientOffersProvider(const OfferQuery.active());
    try {
      while (mounted) {
        final before = ref.read(provider).valueOrNull;
        if (before == null ||
            !before.hasMore ||
            before.isLoadingMore ||
            before.isRefreshing) {
          break;
        }
        await ref.read(provider.notifier).loadMore();
        if (!mounted) break;
        final after = ref.read(provider).valueOrNull;
        if (after == null || after.page <= before.page) break;
      }
    } finally {
      if (mounted) setState(() => _loadingAllOffers = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        unawaited(ref.read(clientActiveRequestsProvider.notifier).loadMore());
        unawaited(
          ref
              .read(clientOffersProvider(const OfferQuery.active()).notifier)
              .loadMore(),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(clientActiveRequestsProvider.notifier).refreshIfStale(),
      );

      unawaited(
        ref
            .read(clientOffersProvider(const OfferQuery.active()).notifier)
            .refreshIfStale(),
      );
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
    final flow = ProkatFlowScope.maybeOf(context);

    final requestsAsync = ref.watch(clientActiveRequestsProvider);
    final offersAsync = ref.watch(
      clientOffersProvider(const OfferQuery.active()),
    );
    final offersState = offersAsync.valueOrNull;

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
                subtitle: l10n.loadContentRetryHint,
              ),
            ],
          ),

          data: (query) {
            final requests = query.items;

            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: flow == null ? null : const EdgeInsets.all(16),
              children: [
                if (flow != null &&
                    (offersAsync.hasError || offersState?.refreshError != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Text(
                          l10n.somethingWentWrong,
                          style: AppFonts.body14(context)
                              .copyWith(color: flow.secondary),
                        ),
                        TextButton(
                          onPressed: () => unawaited(
                            ref
                                .read(
                                  clientOffersProvider(
                                    const OfferQuery.active(),
                                  ).notifier,
                                )
                                .refresh(),
                          ),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                if (requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: flow != null
                        ? _FlowEmptyRequestsTile(
                            onCreate: () =>
                                context.push(AppRoutes.clientRequestsCreate),
                          )
                        : EmptyStateTile(
                            imageName: 'empty_requests.png',
                            title: l10n.noRequestsAtMoment,
                            subtitle: l10n.noActiveRequests,
                            actionButton: flow != null
                                ? ProkatFlowPrimaryButton(
                                    title: l10n.createRequest,
                                    onPressed: () => context.push(
                                      AppRoutes.clientRequestsCreate,
                                    ),
                                  )
                                : AppElevatedButton(
                                    title: l10n.createRequest,
                                    onTap: () => context.push(
                                      AppRoutes.clientRequestsCreate,
                                    ),
                                  ),
                          ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    separatorBuilder: (context, index) => flow != null
                        ? const SizedBox(height: 24)
                        : Divider(
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
                        key: ValueKey(r.id),
                        request: r,
                        offers: requestOffers,
                        offersLoaded: offersState != null,
                        offersComplete:
                            offersState != null &&
                            !offersState.hasMore &&
                            !offersState.isLoadingMore &&
                            !offersState.isRefreshing &&
                            offersState.refreshError == null,
                        offersLoading:
                            _loadingAllOffers ||
                            (offersState?.isLoadingMore ?? false),
                        onLoadAllOffers: () => unawaited(_loadAllOffers()),
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

class _FlowEmptyRequestsTile extends StatelessWidget {
  const _FlowEmptyRequestsTile({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final flow = ProkatFlowScope.maybeOf(context)!;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: flow.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: flow.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: EmptyStateArtwork(imageName: 'empty_requests.png'),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noRequestsAtMoment,
            textAlign: TextAlign.center,
            style: AppFonts.headingS(context).copyWith(color: flow.title),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noActiveRequests,
            textAlign: TextAlign.center,
            style: AppFonts.body14(context).copyWith(color: flow.secondary),
          ),
          const SizedBox(height: 24),
          ProkatFlowPrimaryButton(
            title: l10n.createRequest,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}
