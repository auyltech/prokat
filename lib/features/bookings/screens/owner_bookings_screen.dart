import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_booking_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerBookingsScreen extends ConsumerStatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  ConsumerState<OwnerBookingsScreen> createState() =>
      _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends ConsumerState<OwnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        ref.read(ownerActiveBookingsProvider.notifier).loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ownerActiveBookingsProvider.notifier).refreshIfStale();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final bookingsAsync = ref.watch(ownerActiveBookingsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(ownerActiveBookingsProvider.notifier).refresh();
        },
        child: bookingsAsync.when(
          loading: () => const OwnerBookingSkeleton(),

          error: (error, stackTrace) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: EmptyStateTile(
                  icon: Icons.cancel,
                  title: l10n.errorLoadingOrders,
                  subtitle: error.toString(),
                ),
              ),
            ],
          ),

          data: (query) {
            final bookings = query.items;

            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (bookings.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: EmptyStateTile(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.noBookingsFound,
                      subtitle:
                          "You don't have any active orders at the moment",
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bookings.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.7),
                    ),
                    itemBuilder: (context, index) {
                      return OwnerBookingTile(booking: bookings[index]);
                    },
                  ),

                if (query.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (!query.hasMore && bookings.isNotEmpty)
                  const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}
