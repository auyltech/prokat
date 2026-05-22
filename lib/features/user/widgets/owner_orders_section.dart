import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/widgets.dart/owner_booking_skeleton.dart';
import 'package:prokat/features/bookings/widgets/owner_dashboard_booking_tile.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerOrdersSection extends ConsumerStatefulWidget {
  const OwnerOrdersSection({super.key});

  @override
  ConsumerState<OwnerOrdersSection> createState() => _OwnerOrdersSectionState();
}

class _OwnerOrdersSectionState extends ConsumerState<OwnerOrdersSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final bookingsState = ref.watch(bookingProvider);

    final upcomingJobs = bookingsState.ownerBookings
        .where((b) => b.status.toLowerCase() == BookingStatus.confirmed.name)
        .toList();

    final pendingJobs = bookingsState.ownerBookings
        .where((b) => b.status.toLowerCase() == BookingStatus.created.name)
        .toList();

    final pendingCount = pendingJobs.isEmpty ? 0 : pendingJobs.length;
    final confirmedCount = upcomingJobs.isEmpty ? 0 : upcomingJobs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section ---
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: colorScheme.secondary,
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.activeOrders,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '$pendingCount ${l10n.newOrderCount} - $confirmedCount ${l10n.confirmedOrderCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed: () => context.push(AppRoutes.ownerBookings),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.manage,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (bookingsState.isLoading)
          const OwnerBookingSkeleton()
        else if (upcomingJobs.isEmpty)
          EmptyStateTile(title: l10n.noOrdersYet)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
