import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final bookingState = ref.watch(bookingProvider);

    final bookingHistory = bookingState.ownerBookings
        .where(
          (b) =>
              b.status == BookingStatus.completed ||
              b.status == BookingStatus.cancelled ||
              b.status == BookingStatus.rejected ||
              b.status == BookingStatus.failed,
        )
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bookingProvider.notifier).getOwnerBookings();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchBox(placeholder: l10n.search),
            ),

            if (bookingState.isLoading)
              const RequestTileSkeleton()
            else if (bookingState.error != null)
              EmptyStateTile(title: l10n.errorLoadingOrders)
            else if (bookingHistory.isEmpty)
              EmptyStateTile(title: l10n.noOrderHistory)
            else
              ListView.separated(
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
                itemCount: bookingHistory.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: OwnerBookingTile(booking: bookingHistory[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
