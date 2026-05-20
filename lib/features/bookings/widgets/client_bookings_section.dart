import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/bookings/widgets/client_dashboard_booking_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientBookingsSection extends ConsumerStatefulWidget {
  const ClientBookingsSection({super.key});

  @override
  ConsumerState<ClientBookingsSection> createState() =>
      _ClientBookingsSectionState();
}

class _ClientBookingsSectionState extends ConsumerState<ClientBookingsSection> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).getUserBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final bookingState = ref.watch(bookingProvider);

    final upcoming = bookingState.bookings
        .where((b) => b.status == "CREATED" || b.status == "CONFIRMED")
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.activeOrders,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),

            IconButton(
              onPressed: () => context.push(AppRoutes.clientOrders),
              icon: Icon(
                Icons.task_outlined,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
              tooltip: l10n.myRequests,
            ),
          ],
        ),

        const SizedBox(height: 6),

        if (bookingState.isLoading)
          EmptyStateTile(title: l10n.loading)
        else if (bookingState.error != null)
          EmptyStateTile(title: l10n.error, subtitle: l10n.couldNotLoadOrders)
        else if (upcoming.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noActiveOrders,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.currentOrdersWillAppearHere,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          Column(
            children: upcoming
                .map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClientDashboardBookingTile(booking: booking),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
