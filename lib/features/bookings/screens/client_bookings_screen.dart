import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/page_header.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/user/widgets/client_booking_tile.dart';

class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  ConsumerState<ClientBookingsScreen> createState() =>
      ClientBookingsScreenState();
}

class ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

    final authSession = ref.watch(authProvider).session;
    final bookingState = ref.watch(bookingProvider);

    final upcoming = bookingState.bookings
        .where(
          (b) =>
              b.status.toUpperCase() == "CREATED" ||
              b.status.toUpperCase() == "CONFIRMED",
        )
        .toList();

    final draft = bookingState.bookings
        .where((b) => b.status.toUpperCase() == "DRAFT")
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        children: [
          PageHeader(
            title: "My Orders",
            onBack: () => context.pop(),
            trailing: IconButton(
              onPressed: () => context.push(
                "${AppRoutes.clientOrders}${AppRoutes.clientOrdersHistory}",
              ),
              icon: Icon(
                Icons.history,
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              tooltip: "Order History",
            ),
          ),

          // 1. High-Priority Draft Card (Refined Orange)
          if (draft.isNotEmpty) _EnhancedDraftCard(booking: draft.first),

          // 1. Remove Expanded - Slivers don't work inside it
          if (authSession == null)
            EmptyStateTile(
              title: "Login to create and view bookings",
              icon: Icons.login_outlined,
            )
          else if (bookingState.isLoading)
            EmptyStateTile(title: "Loading Orders...")
          else if (bookingState.error != null)
            EmptyStateTile(title: "Error Loading Orders")
          else if (upcoming.isEmpty)
            EmptyStateTile(
              title: 'No bookings found',
              icon: Icons.inventory_2_outlined,
            )
          else
            Padding(
              padding: EdgeInsets.all(24),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcoming.length,
                itemBuilder: (context, index) {
                  final booking = upcoming[index];
                  return ClientBookingTile(booking: booking);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EnhancedDraftCard extends StatelessWidget {
  final BookingModel booking;
  const _EnhancedDraftCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    const draftColor = Color(0xFFD97706); // Industrial Amber

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: draftColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: draftColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: draftColor, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DRAFT INCOMPLETE',
                  style: TextStyle(
                    color: draftColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Finish your booking request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                context.push('/equipment/${booking.equipment?.id}/book'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: draftColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'RESUME',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
