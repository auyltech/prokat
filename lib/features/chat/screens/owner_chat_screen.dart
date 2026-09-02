import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/logger.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/chat_message_list.dart';
import 'package:prokat/features/chat/widgets/chat_thread_load_error.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const OwnerChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends ConsumerState<OwnerChatScreen> {
  PriceNegotiationQuery? _entryNegotiationQuery;
  OfferQuery? _entryOfferQuery;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() async {
        try {
          ref
              .read(chatMessagesProvider(widget.chatId).notifier)
              .dismissDisplayedPush();
          await Future.wait([
            ref
                .read(currentChatProvider(widget.chatId).notifier)
                .refreshIfStale(),
            ref
                .read(chatMessagesProvider(widget.chatId).notifier)
                .refreshIfStale(),
          ]);
        } catch (error, stackTrace) {
          // Socket handshake is recorded in AppSocketService. Do not let a
          // leftover throw from this microtask become a second Crashlytics fatal.
          Logger.log('OwnerChatScreen.initState: $error\n$stackTrace');
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatAsync = ref.watch(currentChatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    final currentChat = chatAsync.valueOrNull;
    final messages = messagesAsync.valueOrNull?.items ?? const [];

    final booking = currentChat?.booking;

    final lastOffer = currentChat?.getActiveOffer();
    final requestId = (currentChat?.requestId ?? currentChat?.request?.id ?? '')
        .trim();
    final offerQuery = requestId.isEmpty
        ? null
        : OfferQuery(filter: OfferListFilter.active, requestId: requestId);
    if (offerQuery != null && offerQuery != _entryOfferQuery) {
      _entryOfferQuery = offerQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(ownerOffersProvider(offerQuery).notifier).refreshIfStale(),
        );
      });
    }

    final negotiationQuery = priceNegotiationQueryFor(
      bookingId: booking?.id,
      offerId: lastOffer?.id,
    );
    if (negotiationQuery != null &&
        negotiationQuery != _entryNegotiationQuery) {
      _entryNegotiationQuery = negotiationQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref
              .read(priceNegotiationsProvider(negotiationQuery).notifier)
              .refreshIfStale(),
        );
      });
    }
    final negotiations = negotiationQuery == null
        ? const []
        : ref
                  .watch(priceNegotiationsProvider(negotiationQuery))
                  .valueOrNull
                  ?.items ??
              const [];
    final pendingNegotiation = negotiations
        .where((item) => item.status == PriceNegotiationStatus.created)
        .firstOrNull;
    final pendingNegotiationId = (pendingNegotiation?.id ?? '').trim();

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final chatConfig = getChatConfig(
      chat: currentChat,
      hasNegotiation: pendingNegotiation != null,
      pendingFromMe:
          pendingNegotiationId.isNotEmpty &&
          currentUserId.isNotEmpty &&
          (pendingNegotiation?.senderId ?? '').trim() != currentUserId,
      reviewSubmitted: reviewSubmitted,
      l10n: l10n,
      mode: AppMode.ownerMode,
    );

    return Theme(
      data: theme.copyWith(
        bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
          backgroundColor: theme.colorScheme.surface,
        ),
      ),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Column(
          children: [
            if ((chatAsync.hasError || messagesAsync.hasError) &&
                messages.isEmpty)
              Expanded(
                child: ChatThreadLoadError(
                  error: chatAsync.error ?? messagesAsync.error ?? '',
                  onRetry: () async {
                    await ref
                        .read(currentChatProvider(widget.chatId).notifier)
                        .refresh();
                    await ref
                        .read(chatMessagesProvider(widget.chatId).notifier)
                        .refresh();
                  },
                ),
              )
            else
              Expanded(
                child: Container(
                  color: theme.colorScheme.surface,
                  child: ChatMessageList(
                    chatId: widget.chatId,
                    currentUserId: currentUserId,
                    mode: AppMode.ownerMode,
                    currentChat: currentChat,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: SendMessageForm(
          chatId: widget.chatId,
          chatStatus: chatConfig.status,
          mode: AppMode.ownerMode,
          currentChat: currentChat,
          actionBarTitle: chatConfig.actionBartitle,
        ),
      ),
    );
  }
}
