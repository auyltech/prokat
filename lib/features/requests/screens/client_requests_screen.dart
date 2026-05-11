import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/page_header.dart';
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
          PageHeader(
            title: "My Requests",
            onBack: () => context.pop(),
            trailing: IconButton(
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
            EmptyStateTile(
              title: "You don't have any active requests",
              icon: Icons.description_outlined,
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap:
                        true, // Tells the list to only take the space it needs
                    physics:
                        const NeverScrollableScrollPhysics(), // Stops the inner list from trying to scroll separately
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
                    onPressed: () =>
                        context.push(AppRoutes.clientRequestsCreate),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
