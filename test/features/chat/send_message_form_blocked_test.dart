import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/notifiers/chat_messages_notifier.dart';
import 'package:prokat/features/chat/providers/chat_providers.dart';
import 'package:prokat/features/chat/state/chat_status_detail.dart';
import 'package:prokat/features/chat/widgets/send_message_form.dart';
import 'package:prokat/features/user_safety/models/chat_block_state.dart';

import '../user_safety/user_safety_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    required FakeUserSafetyApi api,
    ChatBlockState? blockState,
    ChatType type = ChatType.direct,
  }) {
    return tester.pumpWidget(
      testApp(
        overrides: [
          ...userSafetyOverrides(api),
          chatMessagesProvider.overrideWith(_EmptyChatMessagesNotifier.new),
        ],
        home: Scaffold(
          bottomNavigationBar: SendMessageForm(
            chatId: 'chat-1',
            mode: AppMode.clientMode,
            chatStatus: ChatStatusDetail.offercreated,
            type: type,
            currentChat: ChatModel(
              id: 'chat-1',
              type: type,
              blockState: blockState,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('blocked by me: banner with unblock replaces the composer', (
    tester,
  ) async {
    final api = FakeUserSafetyApi();
    await pumpForm(
      tester,
      api: api,
      blockState: const ChatBlockState(
        isBlocked: true,
        isBlockedByMe: true,
        counterpartUserId: 'user-b',
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('chat-blocked-banner')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byKey(const ValueKey('chat-unblock-button')));
    await tester.pump();
    expect(api.unblockCalls, ['user-b']);
  });

  testWidgets('blocked by the other side: banner without unblock', (
    tester,
  ) async {
    await pumpForm(
      tester,
      api: FakeUserSafetyApi(),
      blockState: const ChatBlockState(
        isBlocked: true,
        isBlockedByMe: false,
        counterpartUserId: 'user-b',
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('chat-blocked-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-unblock-button')), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('not blocked or no blockState keeps the composer', (
    tester,
  ) async {
    await pumpForm(
      tester,
      api: FakeUserSafetyApi(),
      blockState: const ChatBlockState(isBlocked: false, isBlockedByMe: false),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-blocked-banner')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    await pumpForm(tester, api: FakeUserSafetyApi());
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('support chat ignores blockState', (tester) async {
    await pumpForm(
      tester,
      api: FakeUserSafetyApi(),
      type: ChatType.support,
      blockState: const ChatBlockState(isBlocked: true, isBlockedByMe: true),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-blocked-banner')), findsNothing);
  });
}

class _EmptyChatMessagesNotifier extends ChatMessagesNotifier {
  @override
  Future<QueryState<ChatMessageModel>> build(String arg) async {
    return const QueryState(itemsPerPage: 20, count: 0);
  }
}
