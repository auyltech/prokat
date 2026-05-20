import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/widgets.dart/client_request_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientRequestsHistoryScreen extends ConsumerWidget {
  const ClientRequestsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authSession = ref.watch(authProvider).session;
    final state = ref.watch(requestProvider);

    final past = state.requests
        .where((r) => ["ACCEPTED", "CANCELLED", "EXPIRED"].contains(r.status))
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
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
              l10n.requestsHistory,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => authSession == null ? null : context.pop(),
                icon: Icon(
                  Icons.list,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
                tooltip: l10n.activeRequestsTooltip,
              ),
            ],
            actionsPadding: const EdgeInsets.only(right: 12),
          ),

          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4E73DF)),
              ),
            )
          else if (state.error != null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  "Error: ${state.error}",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          else if (past.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noHistoryFound,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  l10n.pastRequests,
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClientRequestTile(request: past[index]),
                  );
                }, childCount: past.length),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
