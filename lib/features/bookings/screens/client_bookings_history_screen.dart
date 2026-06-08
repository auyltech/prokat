import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/user/widgets/client_booking_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientBookingsHistoryScreen extends ConsumerStatefulWidget {
  const ClientBookingsHistoryScreen({super.key});

  @override
  ConsumerState<ClientBookingsHistoryScreen> createState() =>
      ClientBookingsHistoryScreenState();
}

class ClientBookingsHistoryScreenState
    extends ConsumerState<ClientBookingsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Theme Constants
  final bgColor = const Color(0xFF121417);
  final accentColor = const Color(0xFF4E73DF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).getUserBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authSession = ref.watch(authProvider).session;
    final bookingState = ref.watch(bookingProvider);

    final history = bookingState.bookings
        .where(
          (b) =>
              b.status == BookingStatus.completed ||
              b.status == BookingStatus.cancelled ||
              b.status == BookingStatus.rejected,
        )
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        children: [
          if (authSession == null)
            EmptyStateTile(
              title: "Login to create and view bookings",
              icon: Icons.login_outlined,
            )
          else if (bookingState.error != null)
            EmptyStateTile(title: l10n.errorLoadingOrders, icon: Icons.error)
          else if (history.isEmpty)
            EmptyStateTile(
              title: l10n.noOrderHistory,
              subtitle: 'No bookings found',
            )
          else
            ListView.separated(
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
                indent: 16,
                endIndent: 16,
              ),
              itemCount: history.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ClientBookingTile(booking: history[index]),
              ),
            ),
        ],
      ),
    );
  }
}
