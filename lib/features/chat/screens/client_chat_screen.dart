import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/client_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
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
    Future.microtask(() {
      ref.read(chatProvider.notifier).openChatById(widget.chatId);
      // ref.read(offersProvider.notifier).getUserOffers();
    });
  }

  @override
  void didUpdateWidget(covariant ClientChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() {
        ref.read(chatProvider.notifier).reloadChat(widget.chatId);
        // ref.read(offersProvider.notifier).getUserOffers();
      });
    }
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).leaveCurrentChat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Get current User
    final authState = ref.watch(authProvider);
    final currentUserId = authState.session?.user?.id ?? "";

    final chatState = ref.watch(chatProvider);
    final currentChat = chatState.currentChat;
    final messages = chatState.messages;

    final booking = currentChat?.booking;
    final request = currentChat?.request;

    final chatOwnerId = currentChat?.owner?.id;
    final chatClientId = currentChat?.client?.id;

    final offersState = ref.watch(offersProvider);

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
        .getLastRequestOfferId(request?.id ?? "", "client");

    final negotiation = ref.watch(priceNegotiationProvider);

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final pending = ref
        .watch(priceNegotiationProvider.notifier)
        .getPendingNegotiation(
          bookingId: booking?.id,
          currentUserId: currentUserId,
          mode: "client",
          offerId: lastOfferId,
        );
    final pendingId = (pending?.id ?? '').trim();

    final userId = (currentUserId).trim();

    final ChatStatus chatStatus = getChatStatus(
      bookingStatus: booking?.status,
      requestStatus: request?.status,
      hasNegotiation: pendingId.isNotEmpty,
      hasActiveOffer: hasActiveOffer,
      isOfferPendingFromMe: isOfferPendingFromMe,
      pendingFromMe:
          pendingId.isNotEmpty &&
          userId.isNotEmpty &&
          (pending?.senderId ?? '').trim() != userId,
      workStatus: booking?.workStatus ?? WorkStatus.pending,
      reviewSubmitted: reviewSubmitted,
    );

    // Hold offer for this chat
    OfferModel? requestOffer;
    // Find the offer related to this chat, ie request
    if (request != null) {
      for (final offer in offersState.renterOffers) {
        if (offer.requestId == request.id) {
          requestOffer = offer;
          break;
        }
      }
    }

    final isWorkCompleted = chatStatus == ChatStatus.workcompleted;
    final isOrderCanceled = chatStatus == ChatStatus.bookingcancelled;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(chatProvider.notifier).reloadChat(widget.chatId);
        },
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Text(booking?.status.name ?? ""),
                // Text(request?.status.name ?? ""),
                // Text(pendingId),
                // Text(chatStatus.name),

                if (chatState.error != null && messages.isEmpty)
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
                              chatState.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => ref
                                  .read(chatProvider.notifier)
                                  .openChatById(widget.chatId),
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: ListView.separated(
                        reverse: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 4),
                        itemCount: (booking != null || request != null)
                            ? messages.length + 1
                            : messages.length,
                        itemBuilder: (context, index) {
                          final hasBookingHeader =
                              booking != null || request != null;

                          if (hasBookingHeader) {
                            if (index == 0) {
                              // if (request != null) {
                              //   return RequestMessageBubble(request: request);
                              // }
                              // if (booking != null) {
                              //   return BookingMessageBubble(booking: booking);
                              // }
                              return const SizedBox.shrink();
                            }
                          }

                          // 1. Shift index by 1 if header is present
                          final messageIndex = hasBookingHeader
                              ? index - 1
                              : index;

                          // 2. Invert the index so oldest messages (index 0 in data) render at the top
                          final invertedIndex =
                              messages.length - 1 - messageIndex;

                          final message = messages[invertedIndex];
                          final isMe =
                              message.senderId == currentUserId ||
                              message.senderId == 'me';

                          return MessageBubble(message: message, isMe: isMe);
                        },
                      ),
                    ),
                  ),

                if (booking != null)
                  ClientChatActionBar(
                    chatId: widget.chatId,
                    booking: booking,
                    request: request,
                    chatOwnerId: chatOwnerId,
                    chatClientId: chatClientId,
                  ),

                if (booking == null && request != null && requestOffer != null)
                  OfferChatActionBar(
                    chatStatus: chatStatus,
                    chatId: widget.chatId,
                    requestId: request.id,
                    type: "CLIENT_COUNTER",
                  ),

                // 2. Static input area perfectly pinned to the absolute viewport bottom
                if (booking?.status == BookingStatus.reviewed)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    decoration: BoxDecoration(color: theme.cardColor),
                    child: SafeArea(
                      top: false,
                      child: Text(
                        'Chat locked',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: (isWorkCompleted || isOrderCanceled)
                          ? Colors.transparent
                          : theme.cardColor,
                    ),
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      bottom:
                          true, // Offsets input safely away from home system bar pill
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 0.0,
                          bottom: 12.0,
                        ), // Extra layout lift padding
                        child: (isWorkCompleted || isOrderCanceled)
                            ? const SizedBox.shrink() // 3. Safe empty space that respects screen edges
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: 0.0,
                                  bottom: 12.0,
                                ),
                                child: SendMessageForm(chatStatus: chatStatus),
                              ),
                      ),
                    ),
                  ),
              ],
            ),

            // Floating Loading Indicator Overlay
            if (chatState.isLoadingMessages)
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
    );
  }
}
