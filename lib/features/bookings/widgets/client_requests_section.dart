import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/app_link_button.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/client_request_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/widgets.dart/create_request_tile.dart';

class ClientRequestsSection extends ConsumerStatefulWidget {
  const ClientRequestsSection({super.key});

  @override
  ConsumerState<ClientRequestsSection> createState() =>
      _ClientRequestsSectionState();
}

class _ClientRequestsSectionState extends ConsumerState<ClientRequestsSection> {
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
    final requestState = ref.watch(requestProvider);

    final activeRequests = requestState.requests
        .where((r) => ["CREATED", "VIEWED"].contains(r.status))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "My Requests",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            AppLinkButton(
              label: "View Requests",
              onTap: () => context.push(AppRoutes.clientRequests),
            ),
          ],
        ),

        SizedBox(height: 12),

        if (requestState.isLoading)
          EmptyStateTile(title: "Loading...")
        else if (requestState.error != null)
          EmptyStateTile(title: "Error")
        else if (activeRequests.isEmpty)
          CreateRequestTile()
        else
          ClientRequestTile(request: activeRequests[0]),
      ],
    );
  }
}
