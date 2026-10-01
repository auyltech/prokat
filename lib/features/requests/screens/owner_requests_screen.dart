import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/models/catalog_group.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/providers/owner_fleet_groups_provider.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/state/request_lifetime.dart';
import 'package:prokat/features/requests/widgets.dart/new_request_highlight.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(ownerEquipmentProvider.notifier).refreshIfStale());
      unawaited(ref.refresh(ownerFleetGroupsProvider.future));
      unawaited(
        ref
            .read(ownerOffersProvider(const OfferQuery.active()).notifier)
            .refreshIfStale(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fleet = ref.watch(ownerFleetGroupsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: fleet.when(
        loading: () => const RequestTileSkeleton(),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: EmptyStateTile(
                imageName: 'empty_error.png',
                title: AppLocalizations.of(context)!.errorLoadingRequests,
                subtitle: error.toString(),
              ),
            ),
          ],
        ),
        data: (groups) {
          final resolved = groups.isEmpty
              ? const [CatalogGroup.machinery]
              : groups;
          if (resolved.length < 2) {
            return _OwnerRequestsPane(group: resolved.first);
          }
          final l10n = AppLocalizations.of(context)!;
          return AppTabs(
            titles: [
              for (final group in resolved) _requestTabTitle(l10n, group),
            ],
            children: [
              for (final group in resolved)
                _OwnerRequestsPane(key: ValueKey(group), group: group),
            ],
          );
        },
      ),
    );
  }
}

String _requestTabTitle(AppLocalizations l10n, CatalogGroup group) {
  return switch (group) {
    CatalogGroup.machinery => l10n.rentalRequestsMachineryTab,
    CatalogGroup.equipment => l10n.rentalRequestsEquipmentTab,
  };
}

class _OwnerRequestsPane extends ConsumerStatefulWidget {
  const _OwnerRequestsPane({super.key, required this.group});

  final CatalogGroup group;

  @override
  ConsumerState<_OwnerRequestsPane> createState() => _OwnerRequestsPaneState();
}

class _OwnerRequestsPaneState extends ConsumerState<_OwnerRequestsPane> {
  late final ScrollController _scrollController;
  Timer? _lifetimeTicker;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (!_scrollController.hasClients) return;
        if (_scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 300) {
          return;
        }
        unawaited(
          ref
              .read(ownerActiveRequestsProvider(widget.group).notifier)
              .loadMore(),
        );
        unawaited(
          ref
              .read(ownerOffersProvider(const OfferQuery.active()).notifier)
              .loadMore(),
        );
      });
    _lifetimeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(ownerActiveRequestsProvider(widget.group).notifier).refresh(),
      );
    });
  }

  @override
  void dispose() {
    _lifetimeTicker?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(ownerActiveRequestsProvider(widget.group));
    final offersAsync = ref.watch(
      ownerOffersProvider(const OfferQuery.active()),
    );
    final offersByRequest = <String, List<OfferModel>>{};
    for (final offer
        in offersAsync.valueOrNull?.items ?? const <OfferModel>[]) {
      if (offer.status != OfferStatus.created) continue;
      offersByRequest.putIfAbsent(offer.requestId, () => []).add(offer);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref
              .read(ownerActiveRequestsProvider(widget.group).notifier)
              .refresh(),
          ref.read(ownerEquipmentProvider.notifier).refresh(),
          ref.refresh(ownerFleetGroupsProvider.future),
          ref
              .read(ownerOffersProvider(const OfferQuery.active()).notifier)
              .refresh(),
        ]);
      },
      child: requestsAsync.when(
        loading: () => ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [RequestTileSkeleton()],
        ),
        error: (error, _) => ListView(
          controller: _scrollController,
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
          final requests = query.items
              .where(
                (item) =>
                    requestLifetimeRemaining(item.createdAt) > Duration.zero,
              )
              .toList();

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
                    subtitle: l10n.ownerEmptyRequestsHint,
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
                    final request = requests[index];
                    return NewRequestHighlight(
                      key: ValueKey(request.id),
                      requestId: request.id,
                      child: OwnerRequestTile(
                        request: request,
                        offers: offersByRequest[request.id] ?? const [],
                      ),
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
    );
  }
}
