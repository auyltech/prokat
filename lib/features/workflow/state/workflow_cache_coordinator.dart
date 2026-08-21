import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/bookings/models/booking_status_buckets.dart';
import 'package:prokat/features/bookings/providers/client_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/client_history_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_active_bookings_provider.dart';
import 'package:prokat/features/bookings/providers/owner_history_bookings_provider.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/providers/chat_list_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/requests/providers/client_active_requests_provider.dart';
import 'package:prokat/features/requests/providers/client_history_requests_provider.dart';
import 'package:prokat/features/requests/providers/owner_active_requests_provider.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';
import 'package:prokat/features/workflow/utils/event_id_lru.dart';
import 'package:prokat/features/workflow/utils/workflow_cache_patch.dart';

class WorkflowCacheCoordinator {
  WorkflowCacheCoordinator(this.ref);

  final Ref ref;
  final EventIdLru _eventIds = EventIdLru();

  void apply(WorkflowUpdate update) {
    if (!_eventIds.remember(update.eventId)) return;

    final chatId = update.chatId?.trim() ?? '';
    if (chatId.isNotEmpty && ref.exists(currentChatProvider(chatId))) {
      ref.read(currentChatProvider(chatId).notifier).applyWorkflowDelta(update);
    }

    _applyChatLists(update);
    _applyBookings(update);

    if (update.offers != null && update.offers!.isNotEmpty) {
      ref.invalidate(clientOffersProvider);
      ref.invalidate(ownerOffersProvider);
    }

    if (update.negotiations != null && update.negotiations!.isNotEmpty) {
      ref.invalidate(priceNegotiationsProvider);
    }
  }

  Future<void> resyncAfterReconnect() async {
    final refreshes = <Future<void>>[];

    for (final filter in ChatListFilter.values) {
      final client = clientChatsByFilterProvider(filter);
      if (ref.exists(client)) {
        refreshes.add(ref.read(client.notifier).refresh());
      }
      final owner = ownerChatsByFilterProvider(filter);
      if (ref.exists(owner)) {
        refreshes.add(ref.read(owner.notifier).refresh());
      }
    }

    if (ref.exists(clientActiveBookingsProvider)) {
      refreshes.add(ref.read(clientActiveBookingsProvider.notifier).refresh());
    }
    if (ref.exists(ownerActiveBookingsProvider)) {
      refreshes.add(ref.read(ownerActiveBookingsProvider.notifier).refresh());
    }
    if (ref.exists(clientHistoryBookingsProvider)) {
      refreshes.add(ref.read(clientHistoryBookingsProvider.notifier).refresh());
    }
    if (ref.exists(ownerHistoryBookingsProvider)) {
      refreshes.add(ref.read(ownerHistoryBookingsProvider.notifier).refresh());
    }

    if (ref.exists(clientActiveRequestsProvider)) {
      refreshes.add(ref.read(clientActiveRequestsProvider.notifier).refresh());
    }
    if (ref.exists(ownerActiveRequestsProvider)) {
      refreshes.add(ref.read(ownerActiveRequestsProvider.notifier).refresh());
    }
    if (ref.exists(clientHistoryRequestsProvider)) {
      refreshes.add(ref.read(clientHistoryRequestsProvider.notifier).refresh());
    }

    await Future.wait(refreshes);
  }

  void _applyChatLists(WorkflowUpdate update) {
    var removedFromActive = false;
    var missingFromArchive = false;

    for (final filter in ChatListFilter.values) {
      final client = clientChatsByFilterProvider(filter);
      if (ref.exists(client)) {
        final status = ref.read(client.notifier).applyWorkflowUpdate(update);
        if (filter == ChatListFilter.active &&
            status == WorkflowChatApplyStatus.removed) {
          removedFromActive = true;
        }
        if (filter == ChatListFilter.archived &&
            status == WorkflowChatApplyStatus.notFound) {
          missingFromArchive = true;
        }
      }

      final owner = ownerChatsByFilterProvider(filter);
      if (ref.exists(owner)) {
        final status = ref.read(owner.notifier).applyWorkflowUpdate(update);
        if (filter == ChatListFilter.active &&
            status == WorkflowChatApplyStatus.removed) {
          removedFromActive = true;
        }
        if (filter == ChatListFilter.archived &&
            status == WorkflowChatApplyStatus.notFound) {
          missingFromArchive = true;
        }
      }
    }

    if (removedFromActive || missingFromArchive) {
      if (ref.exists(clientChatsByFilterProvider(ChatListFilter.archived))) {
        unawaited(
          ref
              .read(
                clientChatsByFilterProvider(ChatListFilter.archived).notifier,
              )
              .invalidate(),
        );
      }
      if (ref.exists(ownerChatsByFilterProvider(ChatListFilter.archived))) {
        unawaited(
          ref
              .read(
                ownerChatsByFilterProvider(ChatListFilter.archived).notifier,
              )
              .invalidate(),
        );
      }
    }
  }

  void _applyBookings(WorkflowUpdate update) {
    final booking = update.booking;
    if (booking == null) return;

    final isHistory = isHistoryBookingStatus(booking.status);

    void applyActive({
      required bool exists,
      required BookingQueryApplyStatus Function() apply,
      required Future<void> Function() refresh,
      required Future<void> Function() invalidateHistory,
    }) {
      if (!exists) return;
      final status = apply();
      if (status == BookingQueryApplyStatus.removed) {
        unawaited(invalidateHistory());
      } else if (status == BookingQueryApplyStatus.notFound && !isHistory) {
        unawaited(refresh());
      }
    }

    applyActive(
      exists: ref.exists(clientActiveBookingsProvider),
      apply: () => ref
          .read(clientActiveBookingsProvider.notifier)
          .applyBookingDelta(booking),
      refresh: () => ref.read(clientActiveBookingsProvider.notifier).refresh(),
      invalidateHistory: () async {
        if (ref.exists(clientHistoryBookingsProvider)) {
          await ref.read(clientHistoryBookingsProvider.notifier).invalidate();
        }
      },
    );

    applyActive(
      exists: ref.exists(ownerActiveBookingsProvider),
      apply: () => ref
          .read(ownerActiveBookingsProvider.notifier)
          .applyBookingDelta(booking),
      refresh: () => ref.read(ownerActiveBookingsProvider.notifier).refresh(),
      invalidateHistory: () async {
        if (ref.exists(ownerHistoryBookingsProvider)) {
          await ref.read(ownerHistoryBookingsProvider.notifier).invalidate();
        }
      },
    );

    if (isHistory) {
      if (ref.exists(clientHistoryBookingsProvider)) {
        final status = ref
            .read(clientHistoryBookingsProvider.notifier)
            .applyBookingDelta(booking);
        if (status == BookingQueryApplyStatus.notFound) {
          unawaited(
            ref.read(clientHistoryBookingsProvider.notifier).invalidate(),
          );
        }
      }
      if (ref.exists(ownerHistoryBookingsProvider)) {
        final status = ref
            .read(ownerHistoryBookingsProvider.notifier)
            .applyBookingDelta(booking);
        if (status == BookingQueryApplyStatus.notFound) {
          unawaited(
            ref.read(ownerHistoryBookingsProvider.notifier).invalidate(),
          );
        }
      }
    }
  }
}
