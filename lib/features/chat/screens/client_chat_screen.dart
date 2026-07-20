import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/chat_status_only_bar.dart';
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
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref.read(chatSocketServiceProvider).joinChat(widget.chatId);

      await ref.read(chatProvider(widget.chatId).notifier).refresh();

      await ref
          .read(chatMessagesProvider(widget.chatId).notifier)
          .refreshIfStale();
    });
  }

  @override
  void didUpdateWidget(covariant ClientChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() async {
        await ref.read(chatProvider(widget.chatId).notifier).refresh();

        await ref.read(chatMessagesProvider(widget.chatId).notifier).refresh();
      });
    }
  }

  @override
  void dispose() {
    ref.read(chatSocketServiceProvider).leaveChat(widget.chatId);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Get current User
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    // final chatState = ref.watch(chatProvider);
    // final currentChat = chatState.currentChat;
    // final messages = chatState.messages
    //     .where((item) => item.chatId == currentChat?.id)
    //     .toList();

    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
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
    // Offer will always be created by owner and responded by client

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
          await ref.read(chatProvider(widget.chatId).notifier).refresh();

          await ref
              .read(chatMessagesProvider(widget.chatId).notifier)
              .refresh();

          // ref.read(requestProvider.notifier).getClientRequests();
          // ref.read(offersProvider.notifier).getClientOffers();
          // ref.read(bookingProvider.notifier).getClientBookings();
          // ref.read(priceNegotiationProvider.notifier).getPriceNegotiations();
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  // Handle Error
                  if (chatAsync.hasError && messages.isEmpty)
                    Expanded(
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
                                chatAsync.error.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => ref
                                    .read(chatProvider(widget.chatId).notifier)
                                    .refresh(),
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Render Content
                    Expanded(
                      child: ListView.separated(
                        reverse: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 4),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          // 2. Invert the index so oldest messages (index 0 in data) render at the top
                          final invertedIndex = messages.length - 1 - index;
                          final message = messages[invertedIndex];
                          final isMe =
                              message.senderId == currentUserId ||
                              message.senderId == 'me';

                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            mode: AppMode.clientMode,
                          );
                        },
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

              if (booking != null && !showActionBar)
                Positioned(
                  bottom:
                      16 +
                      16, // Added a small margin from the screen bottom edge
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Align(
                      alignment: Alignment
                          .bottomCenter, // 1. CENTERS THE WIDGET HORIZONTALLY
                      child: ChatStatusOnlyBar(
                        text: chatStatus == ChatStatusDetail.bookingreviewed
                            ? "Review Submitted"
                            : "Order Closed",
                      ),
                    ),
                  ),
                ),

              // Floating Loading Indicator Overlay
              if (messagesAsync.valueOrNull?.isRefreshing == true)
                Positioned(
                  top: 16, // Adjust position (e.g., below the app bar)
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      color: theme.colorScheme.surface,
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  ),
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
