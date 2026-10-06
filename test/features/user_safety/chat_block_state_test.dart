import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/user_safety/models/chat_block_state.dart';
import 'package:prokat/features/workflow/utils/workflow_cache_patch.dart';

void main() {
  test('ChatModel.fromJson reads blockState from the chat detail', () {
    final chat = ChatModel.fromJson({
      'id': 'chat-1',
      'type': 'DIRECT',
      'status': 'ACTIVE',
      'blockState': {
        'isBlocked': true,
        'isBlockedByMe': false,
        'counterpartUserId': 'user-b',
      },
    });

    expect(
      chat.blockState,
      const ChatBlockState(
        isBlocked: true,
        isBlockedByMe: false,
        counterpartUserId: 'user-b',
      ),
    );
  });

  test('missing or malformed blockState stays null', () {
    expect(
      ChatModel.fromJson({'id': 'chat-1', 'type': 'DIRECT'}).blockState,
      isNull,
    );
    expect(ChatBlockState.tryParse('yes'), isNull);
    expect(
      ChatBlockState.tryParse({'isBlocked': true, 'counterpartUserId': '  '})
          ?.counterpartUserId,
      isNull,
    );
  });

  test('copyWith keeps and replaces blockState', () {
    const state = ChatBlockState(isBlocked: true, isBlockedByMe: true);
    const chat = ChatModel(id: 'chat-1', blockState: state);

    expect(chat.copyWith().blockState, state);
    const cleared = ChatBlockState(isBlocked: false, isBlockedByMe: false);
    expect(chat.copyWith(blockState: cleared).blockState, cleared);
  });

  test('list-shaped payload without blockState keeps the detail value', () {
    const state = ChatBlockState(
      isBlocked: true,
      isBlockedByMe: true,
      counterpartUserId: 'user-b',
    );
    const previous = ChatModel(id: 'chat-1', blockState: state);
    const incoming = ChatModel(id: 'chat-1');

    final merged = mergeChatPreferringNewerWorkflow(incoming, previous);

    expect(merged.blockState, state);
  });

  test('a fresh blockState from the server wins over the cached one', () {
    const previous = ChatModel(
      id: 'chat-1',
      blockState: ChatBlockState(isBlocked: true, isBlockedByMe: true),
    );
    const fresh = ChatBlockState(isBlocked: false, isBlockedByMe: false);
    const incoming = ChatModel(id: 'chat-1', blockState: fresh);

    final merged = mergeChatPreferringNewerWorkflow(incoming, previous);

    expect(merged.blockState, fresh);
  });
}
