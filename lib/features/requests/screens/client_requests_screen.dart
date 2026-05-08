import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/request_with_offers.dart';

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
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () => context.pop(),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    "My Requests",
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),

                IconButton(
                  onPressed: () => authSession == null
                      ? null
                      : context.push(AppRoutes.clientRequestsCreate),
                  icon: Icon(
                    Icons.add,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  tooltip: "Create Request",
                ),
              ],
            ),
          ),

          if (authSession == null)
            EmptyStateTile(
              title: "Login to create and view requests",
              icon: Icons.login_outlined,
            )
          else if (state.isLoading)
            Center(child: CircularProgressIndicator())
          else if (state.error != null)
            EmptyStateTile(
              title: "Something went wrong!",
              subtitle: "Error loading requests",
              icon: Icons.error_outline,
            )
          else if (active.isEmpty)
            Padding(
              padding: EdgeInsets.all(24),
              child: EmptyStateTile(
                title: "You don't have any active requests",
                icon: Icons.description_outlined,
              ),
            )
          else
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    "ACTIVE REQUESTS",
                    style: theme.textTheme.labelMedium,
                  ),
                ),

                ListView.builder(
                  itemCount: active.length,
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ), // Adjust as needed
                  itemBuilder: (context, index) {
                    final r = active[index];
                    final requestOffers = offersByRequest[r.id] ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RequestWithOffers(
                        request: r,
                        offers: requestOffers,
                        onCancel: () => ref
                            .read(requestProvider.notifier)
                            .cancelRequest(r.id),
                      ),
                    );
                  },
                ),

                PrimaryButton(
                  label: "Create a new request",
                  onPressed: () => context.push(AppRoutes.clientRequestsCreate),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
