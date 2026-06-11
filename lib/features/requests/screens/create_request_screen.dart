import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/widgets.dart/create_request_form.dart';
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

    Future.microtask(() async {
      await ref.read(requestProvider.notifier).getClientRequests();

      if (mounted) {
        ref.read(locationProvider.notifier).getRenterLocations();
      }
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
        .getActiveRequests("client");

    final canCreateRequest = activeRequests.length < maxAllowedRequests;

    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canCreateRequest)
                  const CreateRequestForm()
                else
                  _ActiveRequestLimitView(activeCount: activeRequests.length),
              ],
            ),
          ),
        ],
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

    return Card(
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
