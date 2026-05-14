import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';

class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() =>
      _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen> {
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

    // Logic: Split into actionable categories
    final newBookings = bookingState.ownerBookings
        .where((b) => b.status == "CREATED" || b.status == "CONFIRMED")
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.push(AppRoutes.ownerDashboard),
        ),
        title: Text(
          "My Orders",
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: AppColors.teal700,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.ownerBookingsHistory),
            icon: Icon(
              Icons.history_toggle_off_rounded,
              color: theme.colorScheme.onPrimary,
              size: 24,
            ),
            tooltip: "Job History",
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                if (bookingState.isLoading)
                  RequestTileSkeleton()
                else if (bookingState.error != null)
                  EmptyStateTile(
                    title: "Error Loading Orders",
                    subtitle: bookingState.error.toString(),
                  )
                else if (newBookings.isEmpty)
                  EmptyStateTile(title: "You don't have any active orders")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: newBookings.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OwnerBookingTile(booking: newBookings[index]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
