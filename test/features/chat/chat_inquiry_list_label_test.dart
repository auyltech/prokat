import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/chat/models/chat_list_filter.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/models/chat_sidebar_update.dart';
import 'package:prokat/features/chat/utils/chat_sidebar_update_utils.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:prokat/features/workflow/models/workflow_update.dart';
import 'package:prokat/features/workflow/utils/workflow_cache_patch.dart';
import 'package:prokat/l10n/app_localizations.dart';

// ChatThreadDTO contract from backend chat.dto.ts and chat.dto.test.ts:
// the list has a safe name, unreadCount, and no inquiryEquipment object.
Map<String, dynamic> _listJson({
  String id = 'inquiry',
  String status = 'ACTIVE',
  Object? name = 'Автокран · тест чата',
}) => {
  'id': id,
  'type': 'DIRECT',
  'status': status,
  'bookingId': null,
  'bookingSummary': null,
  'inquiryEquipmentId': 'listing-$id',
  'inquiryEquipmentName': name,
  'requestId': null,
  'client': {
    'id': 'client-1',
    'role': 'CLIENT',
    'firstName': 'Марк',
    'lastName': 'Ванин',
    'imageUrl': null,
  },
  'owner': {
    'id': 'owner-1',
    'role': 'OWNER',
    'firstName': 'Василиса',
    'lastName': 'Самойлова',
    'imageUrl': null,
    'onlineStatus': 'OFFLINE',
  },
  'lastMessage': null,
  'unreadCount': 2,
  'createdAt': '2026-10-14T10:00:00.000Z',
  'updatedAt': '2026-10-14T10:00:00.000Z',
};

void main() {
  test('list JSON retains the label through active and archived lifecycle', () {
    for (final status in ['ACTIVE', 'CLOSED', 'ARCHIVED']) {
      final json = _listJson(status: status);
      expect(json.containsKey('inquiryEquipment'), isFalse);
      final chat = ChatModel.fromJson(json);

      expect(chat.inquiryEquipmentName, 'Автокран · тест чата');
      expect(chat.inquiryEquipment, isNull);
      expect(chat.booking, isNull);
      expect(chat.bookingId, isNull);
      expect(chat.status.name, status.toLowerCase());
      expect(chat.newMessagesCount, 2);
      expect(
        chat.copyWith(newMessagesCount: 0).inquiryEquipmentName,
        chat.inquiryEquipmentName,
      );
      expect(
        chat.copyWith(inquiryEquipmentName: 'Газель').inquiryEquipmentName,
        'Газель',
      );
    }
  });

  test('list label accepts only a nonblank string', () {
    final missing = _listJson()..remove('inquiryEquipmentName');
    expect(ChatModel.fromJson(missing).inquiryEquipmentName, isNull);
    for (final name in [
      null,
      '',
      '  ',
      1,
      {'name': 'Газель'},
    ]) {
      expect(
        ChatModel.fromJson(_listJson(name: name)).inquiryEquipmentName,
        isNull,
      );
    }
    expect(
      ChatModel.fromJson(_listJson(name: '  Газель  ')).inquiryEquipmentName,
      'Газель',
    );
  });

  test('sidebar and workflow deltas preserve a list-only label', () {
    final chat = ChatModel.fromJson(_listJson());
    final sidebar = ChatSidebarUpdate.tryParse({
      'chatId': chat.id,
      'unreadCount': 3,
      'lastMessage': {
        'id': 'message-1',
        'senderId': 'owner-1',
        'type': 'TEXT',
        'content': 'Можно обсудить условия',
        'createdAt': '2026-10-14T10:01:00.000Z',
      },
    })!;
    final sidebarResult = applyChatSidebarUpdateToItems(
      items: [chat],
      update: sidebar,
      currentUserId: 'client-1',
    );
    final updated = sidebarResult.items.single;
    expect(sidebarResult.status, ChatSidebarApplyStatus.applied);
    expect(updated.inquiryEquipmentName, chat.inquiryEquipmentName);
    expect(updated.newMessagesCount, 3);
    expect(updated.lastMessage?.content, 'Можно обсудить условия');

    final workflow = WorkflowUpdate.tryParse({
      'v': 1,
      'eventId': 'inquiry-closed',
      'emittedAt': '2026-10-14T10:02:00.000Z',
      'reason': 'INQUIRY_CLOSED',
      'actorId': 'client-1',
      'chatId': chat.id,
      'chat': {
        'id': chat.id,
        'status': 'CLOSED',
        'updatedAt': '2026-10-14T10:02:00.000Z',
      },
    })!;
    final archived = applyWorkflowUpdateToChatItems(
      items: [updated],
      count: 1,
      filter: ChatListFilter.archived,
      update: workflow,
    );
    expect(archived.status, WorkflowChatApplyStatus.applied);
    expect(archived.items.single.status, ChatStatus.closed);
    expect(
      archived.items.single.inquiryEquipmentName,
      chat.inquiryEquipmentName,
    );
    expect(archived.items.single.inquiryEquipment, isNull);
    expect(archived.items.single.bookingId, isNull);
  });

  test('HTTP merge retains an omitted label and accepts a new label', () {
    final cached = ChatModel.fromJson(_listJson());
    final missing = _listJson(status: 'CLOSED')
      ..remove('inquiryEquipmentName')
      ..['updatedAt'] = '2026-10-14T10:02:00.000Z';
    final merged = mergeChatPreferringNewerWorkflow(
      ChatModel.fromJson(missing),
      cached,
    );
    expect(merged.inquiryEquipmentName, cached.inquiryEquipmentName);
    expect(merged.status, ChatStatus.closed);
    expect(merged.inquiryEquipment, isNull);
    expect(merged.bookingId, isNull);

    final renamed = mergeChatPreferringNewerWorkflow(
      ChatModel.fromJson(_listJson(name: 'Газель')),
      cached,
    );
    expect(renamed.inquiryEquipmentName, 'Газель');
  });

  Future<void> pumpTiles(
    WidgetTester tester,
    List<ChatModel> chats, {
    AppMode mode = AppMode.clientMode,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: chats
                  .map(
                    (chat) => ChatTile(
                      chat: chat,
                      currentUserId: mode == AppMode.clientMode
                          ? 'client-1'
                          : 'owner-1',
                      mode: mode,
                      onTap: () {},
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in [AppMode.clientMode, AppMode.ownerMode]) {
    testWidgets('list tiles distinguish equipment in ${mode.name}', (
      tester,
    ) async {
      await pumpTiles(tester, [
        ChatModel.fromJson(_listJson()),
        ChatModel.fromJson(
          _listJson(id: 'closed-inquiry', status: 'CLOSED', name: 'Газель'),
        ),
      ], mode: mode);

      expect(tester.takeException(), isNull);
      expect(
        find.text(mode == AppMode.clientMode ? 'Василиса' : 'Марк Ванин'),
        findsNWidgets(2),
      );
      expect(find.text('Автокран · тест чата'), findsOneWidget);
      expect(find.text('Газель'), findsOneWidget);
      expect(find.text('Discussion ended'), findsOneWidget);
    });
  }

  testWidgets('tile prefers the full equipment name over the list label', (
    tester,
  ) async {
    final detail = _listJson()
      ..['inquiryEquipment'] = {
        'id': 'listing-inquiry',
        'name': '  Газель из открытого чата  ',
        'model': 'Грузовик',
        'status': 'AVAILABLE',
        'isVisible': true,
        'prices': [],
        'images': [],
        'owner': null,
        'category': null,
        'city': null,
        'rentCondition': null,
      };
    await pumpTiles(tester, [ChatModel.fromJson(detail)]);

    expect(find.text('Газель из открытого чата'), findsOneWidget);
    expect(find.text('Автокран · тест чата'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tile omits a missing or blank equipment label', (tester) async {
    await pumpTiles(tester, [ChatModel.fromJson(_listJson(name: '  '))]);

    expect(find.text('Василиса'), findsOneWidget);
    expect(find.text('Автокран · тест чата'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
