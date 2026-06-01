import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
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

    final newBookings = bookingState.ownerBookings
        .where((b) => b.status == "CREATED" || b.status == "CONFIRMED")
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bookingProvider.notifier).getUserBookings();
        },
        child: ListView(
          padding: EdgeInsets.all(0),
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
              ListView.separated(
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: newBookings.length,
                itemBuilder: (context, index) =>
                    OwnerBookingTile(booking: newBookings[index]),
              ),
          ],
        ),
      ),
    );
  }
}
