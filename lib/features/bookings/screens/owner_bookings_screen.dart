import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/page_header.dart';
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
      body: ListView(
        children: [
          PageHeader(
            title: "My Orders",
            primaryColor: AppColors.teal700,
            showBack: true,
            trailing: IconButton(
              onPressed: () => context.push(AppRoutes.ownerBookingsHistory),
              icon: Icon(
                Icons.history_toggle_off_rounded,
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              tooltip: "Job History",
            ),
          ),

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
