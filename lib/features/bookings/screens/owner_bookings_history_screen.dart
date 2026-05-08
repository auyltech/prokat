import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';

class OwnerBookingHistoryScreen extends ConsumerStatefulWidget {
  const OwnerBookingHistoryScreen({super.key});

  @override
  ConsumerState<OwnerBookingHistoryScreen> createState() =>
      _OwnerBookingHistoryScreenState();
}

class _OwnerBookingHistoryScreenState
    extends ConsumerState<OwnerBookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(bookingProvider.notifier).getOwnerBookings(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingState = ref.watch(bookingProvider);

    final bookingHistory = bookingState.ownerBookings
        .where(
          (b) =>
              b.status.toLowerCase() == BookingStatus.completed.name ||
              b.status.toLowerCase() == BookingStatus.cancelled.name ||
              b.status.toLowerCase() == BookingStatus.rejected.name ||
              b.status.toLowerCase() == BookingStatus.failed.name,
        )
        .toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: theme.colorScheme.primary,
              leading: IconButton(
                icon: Icon(
                  LucideIcons.chevronLeft,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                "Order History",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              centerTitle: false,
              // actions: [
              //   IconButton(
              //     onPressed: () =>
              //         context.push(AppRoutes.ownerBookingsHistory),
              //     icon: Icon(
              //       Icons.history_toggle_off_rounded,
              //       color: theme.colorScheme.onPrimary,
              //       size: 24,
              //     ),
              //     tooltip: "Active Orders",
              //   ),
              // ],
              // actionsPadding: EdgeInsets.only(right: 12),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: SearchBox(placeholder: "Search..."),
              ),
            ),

            if (bookingState.isLoading)
              SliverToBoxAdapter(child: RequestTileSkeleton())
            else if (bookingState.error != null)
              SliverToBoxAdapter(child: Text("Error Loading orders"))
            else if (bookingHistory.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyStateTile(
                    title: "There are no orders in your history",
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OwnerBookingTile(booking: bookingHistory[index]),
                    ),
                    childCount: bookingHistory.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
