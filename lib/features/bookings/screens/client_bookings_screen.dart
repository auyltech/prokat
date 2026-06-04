import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/draft_booking_tile.dart';
import 'package:prokat/features/user/widgets/client_booking_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  ConsumerState<ClientBookingsScreen> createState() =>
      ClientBookingsScreenState();
}

class ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authSession = ref.watch(authProvider).session;
    final bookingState = ref.watch(bookingProvider);

    final upcoming = bookingState.bookings
        .where(
          (b) =>
              b.status == BookingStatus.created ||
              b.status == BookingStatus.confirmed,
        )
        .toList();

    final draft = bookingState.bookings
        .where((b) => b.status == BookingStatus.draft)
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bookingProvider.notifier).getUserBookings();
        },
        child: ListView(
          children: [
            // 1. High-Priority Draft Card (Refined Orange)
            if (draft.isNotEmpty) DraftBookingTile(booking: draft.first),

            if (authSession == null)
              EmptyStateTile(
                title: l10n.loginToViewBookings,
                icon: Icons.login_outlined,
              )
            else if (bookingState.isLoading)
              EmptyStateTile(title: l10n.loadingOrders)
            else if (bookingState.error != null)
              EmptyStateTile(title: l10n.errorLoadingOrders)
            else if (upcoming.isEmpty)
              EmptyStateTile(
                title: l10n.noBookingsFound,
                icon: Icons.inventory_2_outlined,
              )
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
                itemCount: upcoming.length,
                itemBuilder: (context, index) {
                  final booking = upcoming[index];
                  return ClientBookingTile(booking: booking);
                },
              ),
          ],
        ),
      ),
    );
  }
}
