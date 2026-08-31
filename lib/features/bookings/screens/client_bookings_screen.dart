import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/widgets/draft_booking_tile.dart';
import 'package:prokat/features/requests/widgets.dart/owner_booking_skeleton.dart';
import 'package:prokat/features/bookings/widgets/client_booking_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});

  @override
  ConsumerState<ClientBookingsScreen> createState() =>
      ClientBookingsScreenState();
}

class ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen>
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
        unawaited(ref.read(clientActiveBookingsProvider.notifier).loadMore());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(clientActiveBookingsProvider.notifier).refreshIfStale(),
      );
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

    final bookingsAsync = ref.watch(clientActiveBookingsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          return ref.read(clientActiveBookingsProvider.notifier).refresh();
        },
        child: bookingsAsync.when(
          loading: () => const OwnerBookingSkeleton(),

          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              EmptyStateTile(
                imageName: 'empty_error.png',
                title: l10n.errorLoadingOrders,
                subtitle: error.toString(),
              ),
            ],
          ),

          data: (query) {
            final bookings = query.items;

            final draft = bookings
                .where((b) => b.status == BookingStatus.draft)
                .toList();

            return ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (draft.isNotEmpty) DraftBookingTile(booking: draft.first),

                if (bookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: EmptyStateTile(
                      imageName: 'empty_bookings.png',
                      title: l10n.noBookingsFound,
                      subtitle: l10n.youHaveNoActiveOrders,
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
                      return ClientBookingTile(booking: bookings[index]);
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
