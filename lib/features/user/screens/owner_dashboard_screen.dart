import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/state/booking_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/features/user/widgets/owner_equipment_section.dart';
import 'package:prokat/features/user/widgets/owner_orders_section.dart';
import 'package:prokat/l10n/app_localizations.dart';

// TODO: Remove Screen
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
      ref.read(bookingProvider.notifier).getOwnerBookings();
      ref.read(equipmentProvider.notifier).getOwnerEquipment();
      ref.read(requestProvider.notifier).getOwnerRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final activeRequests = ref
        .watch(requestProvider)
        .ownerRequests
        .where((r) => ["CREATED", "VIEWED"].contains(r.status.name))
        .toList();

    final hasRequests = activeRequests.isNotEmpty;
    final count = activeRequests.length;

    final state = ref.watch(bookingProvider);

    final upcomingJobs = state.ownerBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();

    final pendingJobs = state.ownerBookings
        .where((b) => b.status == BookingStatus.created)
        .toList();

    final activeOrdersCount = upcomingJobs.length + pendingJobs.length;

    final requestValue = hasRequests
        ? '$count ${count == 1 ? l10n.newRequestSingular : l10n.newRequestsPlural}'
        : l10n.noNewRequests;

    final ordersValue = activeOrdersCount == 0
        ? l10n.noOrders
        : activeOrdersCount == 1
        ? '${activeOrdersCount.toString().padLeft(2, '0')} ${l10n.orderUnit}'
        : '${activeOrdersCount.toString().padLeft(2, '0')} ${l10n.ordersUnit}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatCard(
                        context,
                        l10n.clientRequests,
                        requestValue,
                        Colors.blue,
                        AppRoutes.ownerRequests,
                      ),

                      const SizedBox(width: 24),

                      _buildStatCard(
                        context,
                        l10n.activeOrders,
                        ordersValue,
                        Colors.orange,
                        AppRoutes.ownerBookings,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                OwnerEquipmentSection(),

                const SizedBox(height: 24),

                OwnerOrdersSection(),
              ],
            ),
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
            Text(
              label,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
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
