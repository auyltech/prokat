import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/widgets.dart/create_request_form.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  static const int maxAllowedRequests = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(clientActiveRequestsProvider.notifier).refreshIfStale();

      final address = await ref
          .read(locationProvider.notifier)
          .ensureSelectedClientAddress(
            preferredId: ref
                .read(clientProfileProvider)
                .userProfile
                ?.selectedAddressId,
          );
      if (!mounted) return;
      if (address != null) {
        ref.read(requestMutationProvider.notifier).selectLocation(address);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(clientActiveRequestsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.read(clientActiveRequestsProvider.notifier).refresh();
        },
        child: requestsAsync.when(
          loading: () => const RequestTileSkeleton(),

          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              EmptyStateTile(
                imageName: 'empty_error.png',
                title: l10n.errorLoadingRequests,
                subtitle: error.toString(),
              ),
            ],
          ),

          data: (query) {
            final blockingCount = query.items
                .where((request) => occupiesCreateRequestSlot(request.status))
                .length;

            final canCreateRequest = blockingCount < maxAllowedRequests;

            if (canCreateRequest) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                children: [CreateRequestForm()],
              );
            } else {
              return _ActiveRequestLimitView(activeCount: blockingCount);
            }
          },
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

            Text(l10n.activeRequestAlreadyExists, textAlign: TextAlign.center),

            const SizedBox(height: 8),

            Text(
              l10n.activeRequestCount(activeCount),
              textAlign: TextAlign.center,
            ),

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
