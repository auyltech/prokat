import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_with_offers.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';

class ClientRequestsScreen extends ConsumerStatefulWidget {
  const ClientRequestsScreen({super.key});

  @override
  ConsumerState<ClientRequestsScreen> createState() =>
      _ClientRequestsScreenState();
}

class _ClientRequestsScreenState extends ConsumerState<ClientRequestsScreen> {
  Future<void> fetchData() async {
    await ref.read(requestProvider.notifier).getClientRequests();
    await ref.read(offersProvider.notifier).getClientOffers();

    final activeRequests = ref
        .watch(requestProvider.notifier)
        .getActiveRequests("client");

    final hasActiveRequests = activeRequests.isNotEmpty;

    if (!hasActiveRequests && mounted) {
      context.push(AppRoutes.clientRequestsCreate);
    }
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

    final authSession = ref.watch(authProvider).session;
    final state = ref.watch(requestProvider);
    final offersState = ref.watch(offersProvider);

    final activeRequests = ref
        .watch(requestProvider.notifier)
        .getActiveRequests("client");

    final offers = offersState.renterOffers.where(
      (r) => ["CREATED", "VIEWED"].contains(r.status),
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
            if (authSession == null)
              EmptyStateTile(
                title: l10n.loginToViewRequests,
                icon: Icons.login_outlined,
              )
            else if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.error != null)
              EmptyStateTile(
                title: l10n.somethingWentWrong,
                subtitle: l10n.errorLoadingRequests,
                icon: Icons.error_outline,
              )
            else if (activeRequests.isEmpty)
              EmptyStateTile(
                title: l10n.noActiveRequests,
                icon: Icons.description_outlined,
              )
            else
              ListView.separated(
                separatorBuilder: (context, index) => const Divider(),
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
