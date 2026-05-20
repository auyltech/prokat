import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/appstatic/widgets/search_box.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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
              b.status.toLowerCase() == BookingStatus.completed.name ||
              b.status.toLowerCase() == BookingStatus.cancelled.name ||
              b.status.toLowerCase() == BookingStatus.rejected.name ||
              b.status.toLowerCase() == BookingStatus.failed.name,
        )
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
          l10n.orderHistory,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: AppColors.teal700,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SearchBox(placeholder: l10n.search),

                const SizedBox(height: 24),

                if (bookingState.isLoading)
                  const RequestTileSkeleton()
                else if (bookingState.error != null)
                  EmptyStateTile(title: l10n.errorLoadingOrders)
                else if (bookingHistory.isEmpty)
                  EmptyStateTile(title: l10n.noOrderHistory)
                else
                  ListView.builder(
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
        ],
      ),
    );
  }
}
