import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  const notSelectedBody =
      "The client selected another owner's equipment. Don't be discouraged — keep responding to requests and you'll find an order.";

  ChatMessageModel notSelectedMessage() {
    return const ChatMessageModel(
      id: 'evt-1',
      chatId: 'chat-1',
      senderId: 'client-1',
      content: notSelectedBody,
      type: 'EVENT',
      service: 'OFFER',
      meta: {
        'requestId': 'req-1',
        'offerId': 'offer-1',
        'status': 'CLOSED',
        'reason': 'NOT_SELECTED',
      },
    );
  }

  test('offer cards require a full offer DTO id in meta', () {
    expect(
      isOfferCardMessage(
        const ChatMessageModel(
          id: 'msg-1',
          chatId: 'chat-1',
          senderId: 'owner-1',
          content: 'sent an offer',
          type: 'EVENT',
          service: 'OFFER',
          meta: {'id': 'offer-1', 'status': 'CREATED'},
        ),
      ),
      isTrue,
    );
  });

  test('losing-tender EVENT is not treated as an offer card', () {
    expect(isOfferCardMessage(notSelectedMessage()), isFalse);
  });

  testWidgets('shows losing-tender support text instead of an offer card', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MessageBubble(
              message: notSelectedMessage(),
              isMe: false,
              mode: AppMode.ownerMode,
              currentChat: ChatModel(
                id: 'chat-1',
                status: ChatStatus.closed,
                offers: [
                  OfferModel(
                    id: 'offer-1',
                    status: OfferStatus.closed,
                    requestId: 'req-1',
                    chatId: 'chat-1',
                    equipmentId: 'eq-1',
                    price: 2200,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(notSelectedBody), findsOneWidget);
    expect(find.text('1 offer'), findsNothing);
    expect(find.text('Offer'), findsNothing);
  });
}
