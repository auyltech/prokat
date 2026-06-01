import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_with_offers.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientRequestsScreen extends ConsumerStatefulWidget {
  const ClientRequestsScreen({super.key});

  @override
  ConsumerState<ClientRequestsScreen> createState() =>
      _ClientRequestsScreenState();
}

class _ClientRequestsScreenState extends ConsumerState<ClientRequestsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(offersProvider.notifier).getUserOffers();
      ref.read(requestProvider.notifier).getUserRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authSession = ref.watch(authProvider).session;
    final state = ref.watch(requestProvider);
    final offersState = ref.watch(offersProvider);

    final active = state.requests
        .where((r) => ["CREATED", "VIEWED"].contains(r.status))
        .toList();

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
      body: ListView(
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
          else if (active.isEmpty)
            EmptyStateTile(
              title: l10n.noActiveRequests,
              icon: Icons.description_outlined,
            )
          else
            ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: active.length,
              itemBuilder: (context, index) {
                final r = active[index];
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
    );
  }
}
