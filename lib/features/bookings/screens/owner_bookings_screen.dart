import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

    // Logic: Split into actionable categories
    final newBookings = bookingState.ownerBookings
        .where((b) => b.status == "CREATED" || b.status == "CONFIRMED")
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              "My Orders",
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () => context.push(AppRoutes.ownerBookingsHistory),
                icon: Icon(
                  Icons.history_toggle_off_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
                tooltip: "Job History",
              ),
            ],
            actionsPadding: const EdgeInsets.only(right: 12),
          ),

          if (bookingState.isLoading)
            SliverToBoxAdapter(child: RequestTileSkeleton())
          else if (bookingState.error != null)
            SliverToBoxAdapter(child: Text("Error loading orders"))
          else if (newBookings.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyStateTile(
                  title: "You don't have any active orders",
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OwnerBookingTile(booking: newBookings[index]),
                  ),
                  childCount: newBookings.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
