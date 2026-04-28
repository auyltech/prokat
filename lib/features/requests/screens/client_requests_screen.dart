import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
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

    final slivers = <Widget>[
      SliverAppBar(
        automaticallyImplyLeading: false,
        expandedHeight: 60,
        floating: true,
        pinned: true,
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "My Requests",
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => authSession == null
                ? null
                : context.push(AppRoutes.clientRequestsCreate),
            icon: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 24),
            tooltip: "Create Request",
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 12),
      ),
    ];

    if (authSession == null) {
      slivers.add(
        _buildCenteredFallback(
          icon: Icons.login_outlined,
          message: "Login to create and view requests",
        ),
      );
    } else if (state.isLoading) {
      slivers.add(
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (state.error != null) {
      slivers.add(
        _buildCenteredFallback(
          icon: Icons.error_outline,
          message: "Error: ${state.error}",
        ),
      );
    } else if (active.isEmpty) {
      slivers.add(
        _buildCenteredFallback(
          icon: Icons.description_outlined,
          message: "No requests found",
        ),
      );
    } else {
      slivers.addAll([
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text("ACTIVE REQUESTS", style: theme.textTheme.labelMedium),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final r = active[index];
              final requestOffers = offersByRequest[r.id] ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestWithOffers(
                  request: r,
                  offers: requestOffers,
                  onCancel: () =>
                      ref.read(requestProvider.notifier).cancelRequest(r.id),
                ),
              );
            }, childCount: active.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => authSession == null
                    ? null
                    : context.push(AppRoutes.clientRequestsCreate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 26),
                label: const Text(
                  "CREATE A NEW REQUEST",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(top: false, child: CustomScrollView(slivers: slivers)),
    );
  }

  Widget _buildCenteredFallback({
    required IconData icon,
    required String message,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false, // Prevents bounce if content is small
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
