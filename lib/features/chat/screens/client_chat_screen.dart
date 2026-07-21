import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/client_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ClientChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ClientChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends ConsumerState<ClientChatScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatAsync = ref.watch(currentChatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    if (chatAsync.isLoading || messagesAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final loadError = chatAsync.error ?? messagesAsync.error;
    if (loadError != null) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(currentChatProvider(widget.chatId).notifier)
                .refresh();
            await ref
                .read(chatMessagesProvider(widget.chatId).notifier)
                .refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 160),
              const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                loadError.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(currentChatProvider(widget.chatId).notifier)
                        .refresh();
                    await ref
                        .read(chatMessagesProvider(widget.chatId).notifier)
                        .refresh();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.retry),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentChat = chatAsync.valueOrNull;
    final messages = messagesAsync.valueOrNull?.items ?? const [];

    final booking = currentChat?.booking;
    final request = currentChat?.request;
    final chatOwnerId = currentChat?.owner?.id;
    final chatClientId = currentChat?.client?.id;

    final activeOffers = ref
        .watch(offersProvider.notifier)
        .getActiveOffers(request?.id ?? "", "client");

    final hasActiveOffer = ref
        .watch(offersProvider.notifier)
        .hasActiveOffer(request?.id ?? "", "client");

    final isOfferPendingFromMe = activeOffers.firstOrNull != null;

    final lastOfferId = ref
        .read(offersProvider.notifier)
        .getLastRequestOffer(request?.id ?? "", "client")
        ?.id;

    final pendingNegotiation = ref
        .watch(priceNegotiationProvider.notifier)
        .getPendingNegotiation(
          bookingId: booking?.id,
          offerId: lastOfferId,
          currentUserId: currentUserId,
          mode: "client",
        );

    final pendingNegotiationId = (pendingNegotiation?.id ?? '').trim();

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final ChatStatusDetail chatStatus = getChatStatus(
      bookingStatus: booking?.status,
      requestStatus: request?.status,
      hasActiveOffer: hasActiveOffer,
      isOfferPendingFromMe: isOfferPendingFromMe,
      hasNegotiation: pendingNegotiationId.isNotEmpty,
      pendingFromMe:
          pendingNegotiationId.isNotEmpty &&
          currentUserId.isNotEmpty &&
          (pendingNegotiation?.senderId ?? '').trim() != currentUserId,
      workStatus: booking?.workStatus,
      reviewSubmitted: reviewSubmitted,
    );

    final showActionBar =
        !(chatStatus == ChatStatusDetail.bookingreviewed ||
            chatStatus == ChatStatusDetail.bookingcancelled);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(currentChatProvider(widget.chatId).notifier).refresh();

          await ref
              .read(chatMessagesProvider(widget.chatId).notifier)
              .refresh();
        },
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  chatAsync.when(
                    loading: () => const Expanded(
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    ),
                    error: (err, stack) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                err.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => ref
                                    .read(
                                      currentChatProvider(
                                        widget.chatId,
                                      ).notifier,
                                    )
                                    .refresh(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    data: (chat) => Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 4),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final invertedIndex = messages.length - 1 - index;
                          final message = messages[invertedIndex];

                          final isMe =
                              message.senderId == currentUserId ||
                              message.senderId == 'me';

                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            mode: AppMode.clientMode,
                            currentChat: chat,
                          );
                        },
                      ),
                    ),
                  ),

                  if (booking != null && showActionBar)
                    ClientChatActionBar(
                      chatId: widget.chatId,
                      chatStatus: chatStatus,
                      booking: booking,
                      request: request,
                      chatOwnerId: chatOwnerId,
                      chatClientId: chatClientId,
                    ),

                  if (booking == null && request != null && showActionBar)
                    OfferChatActionBar(
                      chatStatus: chatStatus,
                      chatId: widget.chatId,
                      requestId: request.id,
                      mode: "client",
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SendMessageForm(
        chatId: widget.chatId,
        chatStatus: chatStatus,
        mode: AppMode.clientMode,
      ),
    );
  }
}
