import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/widgets.dart/owner_booking_skeleton.dart';
import 'package:prokat/features/bookings/widgets/owner_dashboard_booking_tile.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';

class OwnerOrdersSection extends ConsumerStatefulWidget {
  const OwnerOrdersSection({super.key});

  @override
  ConsumerState<OwnerOrdersSection> createState() => _OwnerOrdersSectionState();
}

class _OwnerOrdersSectionState extends ConsumerState<OwnerOrdersSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookingsState = ref.watch(bookingProvider);

    final upcomingJobs = bookingsState.ownerBookings
        .where((b) => b.status.toLowerCase() == BookingStatus.confirmed.name)
        .toList();

    final pendingJobs = bookingsState.ownerBookings
        .where((b) => b.status.toLowerCase() == BookingStatus.created.name)
        .toList();

    return // Place this inside your SliverList or as a SliverToBoxAdapter
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section ---
        Row(
          children: [
            // 1. Icon with light background (using a different icon for orders)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(
                  alpha: 0.1,
                ), // Secondary or Primary
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: colorScheme.secondary,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            // 2. Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Orders',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${pendingJobs.isEmpty ? 0 : pendingJobs.length.toString().padLeft(2, '0')} new order - ${upcomingJobs.isEmpty ? 0 : upcomingJobs.length.toString().padLeft(2, '0')} confirmed order',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Action Button
            TextButton(
              onPressed: () => context.push(AppRoutes.ownerBookings),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Manage', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 8),

        if (bookingsState.isLoading)
          OwnerBookingSkeleton()
        else if (upcomingJobs.isEmpty)
          EmptyStateTile(title: "No Orders Yet")
        else
          ListView.builder(
            shrinkWrap: true, // Tells the list to only take the space it needs
            physics:
                const NeverScrollableScrollPhysics(), // Stops the inner list from trying to scroll separately
            itemCount: upcomingJobs.length,
            itemBuilder: (context, index) {
              final booking = upcomingJobs[index];
              return OwnerDashboardBookingTile(booking: booking);
            },
          ),
      ],
    );
  }
}
