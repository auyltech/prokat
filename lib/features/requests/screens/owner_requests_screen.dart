import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/requests/models/owner_request_scope.dart';
import 'package:prokat/features/layout/navigation_counts_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/requests/state/request_lifetime.dart';
import 'package:prokat/features/requests/widgets.dart/new_request_highlight.dart';
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
      unawaited(
        ref
            .read(ownerOffersProvider(const OfferQuery.active()).notifier)
            .refreshIfStale(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(navigationCountsProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;
    final palette = ProkatFlowPalette.of(context);

    return ProkatFlowScope(
      palette: palette,
      child: Scaffold(
        backgroundColor: palette.background,
        body: AppTabs(
          titles: [
            '${l10n.ownerRequestsAll}${(counts?.allPendingRequests ?? 0) > 0 ? ' · ${counts!.allPendingRequests}' : ''}',
            '${l10n.ownerRequestsMine}${(counts?.pendingRequests ?? 0) > 0 ? ' · ${counts!.pendingRequests}' : ''}',
          ],
          children: const [
            _OwnerRequestsPane(group: OwnerRequestScope.all),
            _OwnerRequestsPane(group: OwnerRequestScope.mine),
          ],
        ),
      ),
    );
  }
}

class _OwnerRequestsPane extends ConsumerStatefulWidget {
  const _OwnerRequestsPane({required this.group});

  final OwnerRequestScope group;

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
          ref
              .read(ownerOffersProvider(const OfferQuery.active()).notifier)
              .refresh(),
        ]);
      },
      child: requestsAsync.when(
        loading: () => ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [_OwnerRequestsLoading()],
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
                subtitle: l10n.loadContentRetryHint,
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
            padding: const EdgeInsets.all(AppDimens.s16$base),
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppDimens.s12$md),
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

class _OwnerRequestsLoading extends StatelessWidget {
  const _OwnerRequestsLoading();

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    return Semantics(
      label: AppLocalizations.of(context)!.loading,
      child: Container(
        margin: const EdgeInsets.all(AppDimens.s16$base),
        padding: const EdgeInsets.all(AppDimens.s16$base),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(AppDimens.r20$xxl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(AppDimens.r12$lg),
                  ),
                ),
                const SizedBox(width: AppDimens.s12$md),
                Expanded(
                  child: Column(
                    children: [
                      Container(height: 14, color: palette.border),
                      const SizedBox(height: AppDimens.s08$sm),
                      Container(height: 12, color: palette.background),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.s16$base),
            Container(height: 42, color: palette.background),
            const SizedBox(height: AppDimens.s16$base),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ),
      ),
    );
  }
}
