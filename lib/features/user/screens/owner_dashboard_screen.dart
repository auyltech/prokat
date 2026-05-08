import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/bookings/widgets/owner_dashboard_booking_tile.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/requests/widgets.dart/owner_booking_skeleton.dart';
import 'package:prokat/features/user/widgets/balance_tile.dart';
import 'package:prokat/features/user/widgets/owner_dashboard_header.dart';
import 'package:prokat/features/user/widgets/owner_equipment_section.dart';
import 'package:prokat/features/user/widgets/owner_orders_section.dart';
import 'package:prokat/features/user/widgets/rent_an_equipment_tile.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(equipmentProvider.notifier).getOwnerEquipment();
      ref.read(requestProvider.notifier).getOwnerRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeRequests = ref
        .watch(requestProvider)
        .ownerRequests
        .where((r) => ["CREATED", "VIEWED"].contains(r.status))
        .toList();

    final hasRequests = activeRequests.isNotEmpty;
    final count = activeRequests.length;

    final state = ref.watch(bookingProvider);

    // final newRequests = state.ownerBookings
    //     .where((b) => b.status == "CREATED")
    //     .toList();
    final upcomingJobs = state.ownerBookings
        .where((b) => b.status.toLowerCase() == BookingStatus.confirmed.name)
        .toList();

    final pendingJobs = state.ownerBookings
        .where((b) => b.status.toLowerCase() == BookingStatus.created.name)
        .toList();

    final activeOrdersCount = upcomingJobs.length + pendingJobs.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: OwnerDashboardHeader()),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                BalanceTile(
                  minutes: 100,
                  burnRate: "~2 min/hr",
                  progress: 0.15,
                  onTopUp: () {},
                ),

                const SizedBox(height: 24),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatCard(
                        context,
                        "Client Requests",
                        hasRequests
                            ? '$count new ${count == 1 ? 'request' : 'requests'}'
                            : 'No new requests at the moment',
                        // equipmentCount.toString().padLeft(2, '0'),
                        Colors.blue,
                        AppRoutes.ownerRequests,
                      ),

                      const SizedBox(width: 24),

                      _buildStatCard(
                        context,
                        "Active Orders",
                        activeOrdersCount == 0
                            ? "No Orders"
                            : activeOrdersCount == 1
                            ? "01 Order"
                            : "${activeOrdersCount.toString().padLeft(2, '0')} Orders",
                        Colors.orange,
                        AppRoutes.ownerBookings,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Manage Equipment Tile
                OwnerEquipmentSection(),

                const SizedBox(height: 24),

                // 4. Active Orders Section
                OwnerOrdersSection(),
              ]),
            ),
          ),

          /// BOOKINGS SECTION
          if (state.isLoading)
            SliverToBoxAdapter(child: const OwnerBookingSkeleton())
          else if (upcomingJobs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: EmptyStateTile(title: "No Orders Yet"),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final booking = upcomingJobs[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OwnerDashboardBookingTile(booking: booking),
                  );
                }, childCount: upcomingJobs.length),
              ),
            ),

          SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(child: RentAnEquipmentTile()),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatCard(
  BuildContext context,
  String label,
  String value,
  Color color,
  String url,
) {
  final theme = Theme.of(context);

  return Expanded(
    child: GestureDetector(
      onTap: () => context.push(url),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceBright,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
