import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
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
  Future<void> fetchData() async {
    await ref.read(requestProvider.notifier).getClientRequests();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final requestsState = ref.watch(requestProvider);

    final requestsHistory = ref
        .watch(requestProvider.notifier)
        .getRequestHistory(AppMode.clientMode);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          fetchData();
        },
        child: ListView(
          children: [
            if (requestsState.fetchStatus == FetchStatus.loading ||
                (requestsState.fetchStatus == FetchStatus.refreshing &&
                    requestsHistory.isEmpty))
              RequestTileSkeleton()
            else if (requestsState.fetchStatus == FetchStatus.error)
              EmptyStateTile(
                icon: Icons.error_outline,
                title: l10n.errorLoadingRequests,
                subtitle: requestsState.fetchError?.message,
              )
            else if (requestsState.fetchStatus == FetchStatus.empty ||
                (requestsState.fetchStatus == FetchStatus.success &&
                    requestsHistory.isEmpty))
              EmptyStateTile(
                icon: Icons.inventory_2_outlined,
                title: l10n.noRequestsAtMoment,
                subtitle: "You don't have any requests in your history",
              )
            else
              ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor.withValues(alpha: 0.7),
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requestsHistory.length,
                itemBuilder: (context, index) {
                  return ClientRequestTile(request: requestsHistory[index]);
                },
              ),
          ],
        ),
      ),
    );
  }
}
