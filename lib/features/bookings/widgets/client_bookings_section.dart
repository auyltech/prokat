import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/bookings/widgets/client_dashboard_booking_tile.dart';

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

    final bookingState = ref.watch(bookingProvider);

    final upcoming = bookingState.bookings
        .where((b) => b.status == "CREATED" || b.status == "CONFIRMED")
        .toList();

    final completed = bookingState.bookings
        .where((b) => b.status == "COMPLETED")
        .toList();

    if (completed.isNotEmpty) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Orders",
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
              tooltip: "My Orders",
            ),
          ],
        ),

        const SizedBox(height: 6),

        if (upcoming.isEmpty)
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
                  "No active orders right now",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your current requests will appear here",
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
