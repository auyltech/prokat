import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/chat/state/chat_provider.dart';
import 'package:prokat/features/chat/widgets/booking_actions/owner_chat_action_bar.dart';
import 'package:prokat/features/chat/widgets/booking_message_bubble.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/widgets/request_header_bubble.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/chat/widgets/user_avatar.dart';
import 'package:prokat/features/chat/widgets/offer_actions/offer_chat_action_bar.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';

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
    Future.microtask(() {
      ref.read(chatProvider.notifier).openChatById(widget.chatId);

      ref.read(offersProvider.notifier).getOwnerOffers();
    });
  }

  @override
  void didUpdateWidget(covariant OwnerChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId != widget.chatId) {
      Future.microtask(() {
        ref.read(chatProvider.notifier).openChatById(widget.chatId);
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

    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);

    final messages = chatState.messages;
    final currentChat = chatState.currentChat;

    final authUserId = authState.session?.user?.id;

    final currentUserId = (authUserId ?? '').isNotEmpty
        ? authUserId
        : chatState.currentUserId;

    final title = currentChat?.displayTitle(currentUserId ?? "") ?? 'Chat';

    final avatarUrl = currentChat?.displayImageUrl(
      currentUserId: currentUserId,
    );

    final booking = currentChat?.booking;
    final request = currentChat?.request;
    final chatOwnerId = currentChat?.owner?.id;
    final chatClientId = currentChat?.client?.id;
    final offersState = ref.watch(offersProvider);
    OfferModel? requestOffer;
    if (request != null) {
      for (final offer in offersState.ownerOffers) {
        if (offer.requestId == request.id) {
          requestOffer = offer;
          break;
        }
      }
    }

    print(booking?.myReviewId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.teal700,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () =>
              context.push('${AppRoutes.ownerChat}/${widget.chatId}/info'),
          child: Row(
            children: [
              UserAvatar(radius: 22, avatarUrl: avatarUrl, fullName: title),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    if (messages.lastOrNull != null)
                      Text(
                        formatDateTime(
                          messages.last.createdAt,
                          messages.last.createdAt,
                        ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(chatProvider.notifier).reloadChat(widget.chatId);
        },
        child: Column(
          children: [
            if (chatState.isLoadingMessages)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (chatState.error != null && messages.isEmpty)
              Expanded(
                child: Center(
                  child: Text(chatState.error ?? "Error Loading Messages"),
                ),
              )
            else
              Expanded(
                child: Container(
                  color: theme.colorScheme.surface,
                  child: ListView.builder(
                    reverse:
                        false, // Newest messages at bottom, oldest + booking tiles at top
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    // Increase item count by 2 if booking/request tiles exist
                    itemCount:
                        messages.length +
                        ((booking != null || request != null) ? 1 : 0),
                    itemBuilder: (context, index) {
                      final hasBookingHeader =
                          booking != null || request != null;

                      if (hasBookingHeader) {
                        if (index == 0) {
                          if (booking != null) {
                            return BookingMessageBubble(booking: booking);
                          }
                          if (request != null) {
                            return RequestHeaderBubble(request: request);
                          }
                          return const SizedBox.shrink();
                        }
                      }
                      // 1. Shift index by 1 if header is present
                      final messageIndex = hasBookingHeader ? index - 1 : index;

                      // 2. Invert the index so oldest messages (index 0 in data) render at the top
                      final invertedIndex = messages.length - 1 - messageIndex;

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
            if (booking == null && request != null && requestOffer != null)
              OfferChatActionBar(
                chatId: widget.chatId,
                offer: requestOffer,
                type: "OWNER_COUNTER",
              ),

            if ((booking?.status ?? '').trim().toLowerCase() == 'reviewed')
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                decoration: BoxDecoration(color: theme.cardColor),
                child: SafeArea(
                  top: false,
                  child: Text(
                    'Chat locked',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    // top: BorderSide(
                    //   color: theme.dividerColor.withValues(alpha: 0.2),
                    //   width: 1.0,
                    // ),
                  ),
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
                    child: const SendMessageForm(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget _buildInputSection(ThemeData theme, bool isSending) {
  //   return Container(
  //     padding: EdgeInsets.fromLTRB(
  //       16,
  //       12,
  //       16,
  //       MediaQuery.of(context).padding.bottom + 12,
  //     ),
  //     decoration: BoxDecoration(
  //       color: theme.cardColor,
  //       boxShadow: const [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: 10,
  //           offset: Offset(0, -5),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.end,
  //       children: [
  //         Expanded(
  //           child: TextField(
  //             controller: _controller,
  //             minLines: 1,
  //             maxLines: 5,
  //             textCapitalization: TextCapitalization.sentences,
  //             decoration: InputDecoration(
  //               hintText: 'Review offer and reply...',
  //               hintStyle: TextStyle(color: theme.disabledColor),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(24),
  //                 borderSide: BorderSide.none,
  //               ),
  //               fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
  //               filled: true,
  //               contentPadding: const EdgeInsets.symmetric(
  //                 horizontal: 20,
  //                 vertical: 12,
  //               ),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Container(
  //           decoration: BoxDecoration(
  //             color: theme.colorScheme.primary,
  //             shape: BoxShape.circle,
  //           ),
  //           child: IconButton(
  //             onPressed: _sendMessage,
  //             icon: Stack(
  //               clipBehavior: Clip.none,
  //               children: [
  //                 const Icon(Icons.send_rounded, color: Colors.white, size: 20),
  //                 if (isSending)
  //                   Positioned(
  //                     right: -4,
  //                     top: -4,
  //                     child: SizedBox(
  //                       width: 12,
  //                       height: 12,
  //                       child: CircularProgressIndicator(
  //                         strokeWidth: 2,
  //                         valueColor: AlwaysStoppedAnimation<Color>(
  //                           Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
