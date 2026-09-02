import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        unawaited(ref.read(ownerActiveRequestsProvider.notifier).loadMore());
        unawaited(
          ref
              .read(ownerOffersProvider(const OfferQuery.active()).notifier)
              .loadMore(),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(ownerActiveRequestsProvider.notifier).refreshIfStale(),
      );
      unawaited(ref.read(ownerEquipmentProvider.notifier).refreshIfStale());
      unawaited(
        ref
            .read(ownerOffersProvider(const OfferQuery.active()).notifier)
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

    final requestsAsync = ref.watch(ownerActiveRequestsProvider);

    final offersAsync = ref.watch(
      ownerOffersProvider(const OfferQuery.active()),
    );

    final offersByRequest = <String, List<OfferModel>>{};

    for (final offer
        in offersAsync.valueOrNull?.items ?? const <OfferModel>[]) {
      if (![OfferStatus.created].contains(offer.status)) continue;

      offersByRequest.putIfAbsent(offer.requestId, () => []);
      offersByRequest[offer.requestId]!.add(offer);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(ownerActiveRequestsProvider.notifier).refresh(),
            ref.read(ownerEquipmentProvider.notifier).refresh(),
            ref
                .read(ownerOffersProvider(const OfferQuery.active()).notifier)
                .refresh(),
          ]);
        },
        child: requestsAsync.when(
          loading: () => const RequestTileSkeleton(),

          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: EmptyStateTile(
                  imageName: 'empty_error.png',
                  title: l10n.errorLoadingRequests,
                  subtitle: error.toString(),
                ),
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
                    padding: const EdgeInsets.all(12),
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

                      return OwnerRequestTile(
                        request: requests[index],
                        offers: requestOffers,
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
