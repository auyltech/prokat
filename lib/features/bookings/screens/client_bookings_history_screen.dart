import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/user/widgets/client_booking_tile.dart';

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

    final authSession = ref.watch(authProvider).session;
    final bookingState = ref.watch(bookingProvider);

    // final upcoming = bookingState.bookings
    //     .where((b) => b.status == "CREATED" || b.status == "CONFIRMED")
    //     .toList();

    final history = bookingState.bookings
        .where(
          (b) =>
              b.status == "COMPLETED" ||
              b.status == "CANCELLED" ||
              b.status == "REJECTED",
        )
        .toList();

    final draft = bookingState.bookings
        .where((b) => b.status == "DRAFT")
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 60, // Adjust height as needed
              floating: true, // AppBar reappears immediately when scrolling up
              pinned: false, // AppBar hides completely when scrolling down
              backgroundColor: theme.colorScheme.primary,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                "Order History",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              centerTitle: false,
              // actions: [
              //   IconButton(
              //     onPressed: () => context.push(AppRoutes.clientOrders),
              //     icon: Icon(
              //       Icons.timelapse,
              //       color: theme.colorScheme.onPrimary,
              //       size: 24,
              //     ),
              //     tooltip: "Active Orders",
              //   ),
              // ],
            ),

            // 1. High-Priority Draft Card (Refined Orange)
            if (draft.isNotEmpty)
              SliverToBoxAdapter(
                child: _EnhancedDraftCard(booking: draft.first),
              ),

            // 1. Remove Expanded - Slivers don't work inside it
            authSession == null
                ? SliverFillRemaining(
                    // Fills the rest of the screen to center content
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Login to create and view bookings",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : history.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings found',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    sliver: SliverList.separated(
                      // Replaces ListView.separated
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = history[index];
                        return ClientBookingTile(booking: booking);
                      },
                    ),
                  ),
          ],
        ),
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
