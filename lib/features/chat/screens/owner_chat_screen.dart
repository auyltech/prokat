import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/state/chat_status.dart';
import 'package:prokat/features/chat/utils/get_chat_status.dart';
import 'package:prokat/features/chat/widgets/booking_actions/owner_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_bar.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const OwnerChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends ConsumerState<OwnerChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(chatProvider.notifier).openChatById(widget.chatId);
      await ref.read(offersProvider.notifier).getOwnerOffers();
    });
  }

  @override
  void didUpdateWidget(covariant OwnerChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() {
        ref.read(chatProvider.notifier).reloadChat(widget.chatId);
        ref.read(priceNegotiationProvider.notifier).getPriceNegotiations();
        ref.read(offersProvider.notifier).getOwnerOffers();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    ref.read(chatProvider.notifier).leaveCurrentChat();

    super.dispose();
  }

  // void _sendMessage() {
  //   final text = _controller.text.trim();
  //   if (text.isEmpty) {
  //     return;
  //   }

  //   ref.read(chatProvider.notifier).sendMessage(text);
  //   _controller.clear();
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);

    final messages = chatState.messages;
    final currentChat = chatState.currentChat;

    final authUserId = authState.session?.user?.id;

    final currentUserId = (authUserId ?? '').isNotEmpty
        ? authUserId
        : chatState.currentUserId;

    final booking = currentChat?.booking;
    final request = currentChat?.request;
    final chatOwnerId = currentChat?.owner?.id;
    final chatClientId = currentChat?.client?.id;

    final negotiation = ref.watch(priceNegotiationProvider);

    final reviewSubmitted =
        (booking?.myReviewId?.isNotEmpty ?? false) ||
        ref.watch(reviewByBookingProvider(booking?.id ?? "")).hasSubmitted;

    final pending = negotiation.latestPending;
    final pendingId = (pending?.id ?? '').trim();

    final userId = (currentUserId ?? '').trim();

    final ChatStatus chatStatus = getChatStatus(
      bookingStatus: booking?.status ?? BookingStatus.cancelled,
      hasNegotiation: pendingId.isNotEmpty,
      pendingFromMe:
          pendingId.isNotEmpty &&
          userId.isNotEmpty &&
          (pending?.senderId ?? '').trim() != userId,
      workStatus: booking?.workStatus ?? WorkStatus.pending,
      reviewSubmitted: reviewSubmitted,
    );

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
                // Loading Error Indicator
                if (chatState.error != null && messages.isEmpty)
                  Expanded(
                    child: Center(
                      // Centers the entire error block vertically
                      child: SingleChildScrollView(
                        // Prevents overflow on small screens
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh still works
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                size: 48,
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                chatState.error!,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
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
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      color: theme.colorScheme.surface,
                      child: ListView.separated(
                        reverse:
                            false, // Newest messages at bottom, oldest + booking tiles at top
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 4),
                        // Increase item count by 2 if booking/request tiles exist
                        itemCount:
                            messages.length +
                            ((booking != null || request != null) ? 1 : 0),
                        itemBuilder: (context, index) {
                          final hasBookingHeader =
                              booking != null || request != null;

                          if (hasBookingHeader) {
                            if (index == 0) {
                              // if (booking != null) {
                              //   return BookingMessageBubble(booking: booking);
                              // }
                              // if (request != null) {
                              //   return RequestMessageBubble(request: request);
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
                  OwnerChatActionBar(
                    chatId: widget.chatId,
                    booking: booking,
                    chatOwnerId: chatOwnerId,
                    chatClientId: chatClientId,
                  ),

                // Still no booking, but has request
                if (booking == null && request != null)
                  OfferChatActionBar(
                    chatStatus: chatStatus,
                    chatId: widget.chatId,
                    requestId: request.id,
                    type: "OWNER_COUNTER",
                  ),

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
