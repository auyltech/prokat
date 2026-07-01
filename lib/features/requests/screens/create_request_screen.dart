import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/widgets.dart/create_request_form.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  static const int maxAllowedRequests = 1;

  Future<void> fetchData() async {
    final state = ref.read(requestProvider);

    if (state.lastFetchedAt != null) {
      final age = DateTime.now().difference(state.lastFetchedAt!);

      if (age.inMinutes >= 1) {
        await ref.read(requestProvider.notifier).getClientRequests();
      }
    } else if (state.fetchStatus == FetchStatus.initial ||
        state.fetchStatus == FetchStatus.error) {
      await ref.read(requestProvider.notifier).getClientRequests();
    }

    // final activeRequests = ref
    //     .watch(requestProvider.notifier)
    //     .getActiveRequests(AppMode.clientMode);

    // final canCreateRequest = activeRequests.length < maxAllowedRequests;

    // if (!canCreateRequest && mounted) {
    //   context.push(AppRoutes.clientRequests);
    // }

    if (ref.read(locationProvider).fetchStatus == FetchStatus.initial) {
      ref.read(locationProvider.notifier).getClientLocations();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final activeRequests = ref
        .watch(requestProvider.notifier)
        .getActiveRequests(AppMode.clientMode);

    final fetchStatus = ref.watch(requestProvider).fetchStatus;

    final isLoading =
        fetchStatus == FetchStatus.loading ||
        fetchStatus == FetchStatus.refreshing;

    final isError = fetchStatus == FetchStatus.error;

    final isSuccess =
        fetchStatus == FetchStatus.success || fetchStatus == FetchStatus.empty;

    final canCreateRequest =
        isSuccess && (activeRequests.length < maxAllowedRequests);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchData();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isLoading)
              RequestTileSkeleton()
            else if (isError)
              EmptyStateTile(
                icon: Icons.error_outline,
                title: "Error Loading Requests",
              )
            else if (canCreateRequest)
              const CreateRequestForm()
            else
              _ActiveRequestLimitView(activeCount: activeRequests.length),
          ],
        ),
      ),
    );
  }
}

class _ActiveRequestLimitView extends StatelessWidget {
  const _ActiveRequestLimitView({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BaseTile(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.pending_actions_outlined, size: 48),

            const SizedBox(height: 16),

            Text(
              "You already have an active request.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text("$activeCount active request(s)", textAlign: TextAlign.center),

            const SizedBox(height: 20),

            PrimaryButton(
              label: l10n.myRequests,
              onPressed: () {
                context.push(AppRoutes.clientRequests);
              },
            ),
          ],
        ),
      ),
    );
  }
}
