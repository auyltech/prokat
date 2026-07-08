import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/requests/providers/client_history_requests_provider.dart';
import 'package:prokat/features/requests/widgets.dart/client_request_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientRequestsHistoryScreen extends ConsumerStatefulWidget {
  const ClientRequestsHistoryScreen({super.key});

  @override
  ConsumerState<ClientRequestsHistoryScreen> createState() =>
      _ClientRequestsHistoryScreenState();
}

class _ClientRequestsHistoryScreenState
    extends ConsumerState<ClientRequestsHistoryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(clientHistoryRequestsProvider.notifier).loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientHistoryRequestsProvider.notifier).refreshIfStale();
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

    final requestsAsync = ref.watch(clientHistoryRequestsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.read(clientHistoryRequestsProvider.notifier).refresh();
        },
        child: requestsAsync.when(
          loading: () => const RequestTileSkeleton(),

          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              EmptyStateTile(
                icon: Icons.cancel,
                title: l10n.errorLoadingRequests,
                subtitle: error.toString(),
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
                  EmptyStateTile(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.noRequestsAtMoment,
                    subtitle: "You don't have any requests in your history",
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
                      return ClientRequestTile(request: requests[index]);
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
