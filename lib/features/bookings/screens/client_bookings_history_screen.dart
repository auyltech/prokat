import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/providers/client_history_bookings_provider.dart';
import 'package:prokat/features/requests/widgets.dart/owner_booking_skeleton.dart';
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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientHistoryBookingsProvider.notifier).refreshIfStale();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final bookingsAsync = ref.watch(clientHistoryBookingsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(clientHistoryBookingsProvider.notifier).refresh();
        },
        child: bookingsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [OwnerBookingSkeleton()],
          ),

          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              EmptyStateTile(
                icon: Icons.cancel,
                title: l10n.errorLoadingOrders,
                subtitle: error.toString(),
              ),
            ],
          ),

          data: (state) {
            final historyBookings = state.items;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (historyBookings.isEmpty)
                  EmptyStateTile(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.noBookingsFound,
                    subtitle: "You don't have any orders in your history",
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyBookings.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.7),
                    ),
                    itemBuilder: (context, index) {
                      return ClientBookingTile(booking: historyBookings[index]);
                    },
                  ),

                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
