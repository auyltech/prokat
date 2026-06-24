import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_booking_skeleton.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(bookingProvider.notifier);
      final state = ref.read(bookingProvider);

      // Never loaded
      if (state.fetchStatus == FetchStatus.initial) {
        notifier.getOwnerBookings();
        return;
      }

      // Optional stale refresh
      if (state.lastFetchedAt != null) {
        final age = DateTime.now().difference(state.lastFetchedAt!);

        if (age.inMinutes >= 5) {
          notifier.getOwnerBookings();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final bookingState = ref.watch(bookingProvider);

    final historyBookings = bookingState.ownerBookings
        .where(
          (b) =>
              b.status == BookingStatus.completed ||
              b.status == BookingStatus.cancelled ||
              b.status == BookingStatus.rejected ||
              b.status == BookingStatus.failed,
        )
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bookingProvider.notifier).getOwnerBookings();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchBox(placeholder: l10n.search),
            ),

            if (bookingState.fetchStatus == FetchStatus.loading)
              const OwnerBookingSkeleton()
            else if (bookingState.fetchStatus == FetchStatus.error)
              EmptyStateTile(
                icon: Icons.cancel,
                title: l10n.errorLoadingOrders,
                subtitle: bookingState.fetchError?.message,
              )
            else if (bookingState.fetchStatus == FetchStatus.empty ||
                (bookingState.fetchStatus == FetchStatus.success &&
                    historyBookings.isEmpty))
              EmptyStateTile(
                icon: Icons.inventory_2_outlined,
                title: l10n.noBookingsFound,
                subtitle: "You don't have any orders in your history",
              )
            else if (bookingState.fetchStatus == FetchStatus.success ||
                bookingState.fetchStatus == FetchStatus.refreshing)
              ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor.withValues(alpha: 0.7),
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyBookings.length,
                itemBuilder: (context, index) {
                  return OwnerBookingTile(booking: historyBookings[index]);
                },
              )
            else if (bookingState.fetchStatus == FetchStatus.initial)
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
