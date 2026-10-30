import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/widgets/message_bubble.dart';
import 'package:prokat/features/chat/utils/chat_message_utils.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('short chat message keeps time inline at text scale $scale', (
      tester,
    ) async {
      tester.view.reset();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 700),
              textScaler: TextScaler.linear(scale),
            ),
            child: ProkatFlowPage(
              builder: (_) => Scaffold(
                body: MessageBubble(
                  message: ChatMessageModel(
                    id: 'm',
                    chatId: 'c',
                    senderId: 'u',
                    content: 'вау',
                    createdAt: DateTime(2026, 10, 30, 12, 5),
                    readAt: DateTime(2026, 10, 30, 12, 6),
                  ),
                  isMe: true,
                  mode: AppMode.clientMode,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('receipt survives history/socket duplicate merge and image metadata roundtrip', () {
    final message = ChatMessageModel(
      id: 'm',
      chatId: 'c',
      senderId: 'u',
      content: '',
      type: 'IMAGE',
      meta: const {
        'attachment': {'id': 'photo'},
      },
      readAt: DateTime(2026),
    );
    final decoded = ChatMessageModel.fromJson(message.toJson());
    expect(decoded.meta?['attachment'], {'id': 'photo'});
    expect(decoded.localizedContent('en'), 'Photo');
    final merged = mergeMessages(
      [message],
      [message.copyWith().toJson()..remove('readAt')]
          .map(ChatMessageModel.fromJson)
          .toList(),
    );
    expect(merged.single.readAt, DateTime(2026));
  });
}
