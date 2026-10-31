import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/bookings/models/booking_summary_model.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/widgets/chat_tile.dart';
import 'package:prokat/features/chat/widgets/chat_tile_skeleton.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _client = UserModel(
  id: 'client',
  firstName: 'Очень длинное имя клиента для проверки маленького экрана',
);
const _owner = UserModel(
  id: 'owner',
  firstName: 'Компания с длинным названием и дополнительным описанием',
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(320, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: ProkatFlowScope(
          palette: brightness == Brightness.dark
              ? ProkatFlowPalette.dark
              : ProkatFlowPalette.light,
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [child],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final mode in [AppMode.clientMode, AppMode.ownerMode]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets('chat card fits 320px and 2x text: $mode / $brightness', (
        tester,
      ) async {
        var opened = false;
        final chat = ChatModel(
          id: 'discussion',
          client: _client,
          owner: _owner,
          inquiryEquipmentId: 'equipment',
          inquiryEquipmentName:
              'Экскаватор-погрузчик с очень длинным названием',
          newMessagesCount: 987,
          lastMessage: ChatMessageModel(
            id: 'message',
            chatId: 'discussion',
            senderId: 'owner',
            content: 'Длинное сообщение без переносов: ${'Подробности' * 30}',
            createdAt: DateTime.utc(2026, 10, 28, 7, 14),
          ),
        );
        await _pump(
          tester,
          ChatTile(
            chat: chat,
            currentUserId: mode == AppMode.clientMode ? 'client' : 'owner',
            mode: mode,
            onTap: () => opened = true,
          ),
          brightness: brightness,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('99+'), findsOneWidget);
        expect(find.text(chat.inquiryEquipmentName!), findsOneWidget);
        expect(chat.newMessagesCount, 987);
        await tester.tap(find.byType(ChatTile));
        expect(opened, isTrue);
      });
    }
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final completedWork in [false, true]) {
      testWidgets(
        'order status stays readable at 320px and 2x text: completed work $completedWork / $brightness',
        (tester) async {
          final chat = ChatModel(
            id: 'order-chat',
            client: _client,
            owner: _owner,
            bookingId: 'booking',
            bookingSummary: BookingSummaryModel(
              id: 'booking',
              status: completedWork ? 'CONFIRMED' : 'CREATED',
              workStatus: completedWork
                  ? WorkStatus.completed
                  : WorkStatus.pending,
            ),
          );
          await _pump(
            tester,
            ChatTile(
              chat: chat,
              currentUserId: 'owner',
              mode: AppMode.ownerMode,
              onTap: () {},
            ),
            brightness: brightness,
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(ChatTile)),
          )!;
          final label = completedWork
              ? l10n.waitingForClientConfirm
              : l10n.orderCreated;
          final status = find.text(label);
          expect(status, findsOneWidget);
          expect(tester.takeException(), isNull);
          final text = tester.widget<Text>(status);
          final paragraph = tester.renderObject<RenderParagraph>(status);
          expect(text.maxLines, isNull);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.size.width, lessThanOrEqualTo(192));
          if (completedWork) {
            // This existing label cannot fit on one line at this scale.
            expect(
              paragraph
                  .getBoxesForSelection(
                    TextSelection(baseOffset: 0, extentOffset: label.length),
                  )
                  .length,
              greaterThan(1),
            );
          }
        },
      );
    }
  }

  testWidgets(
    'list message timestamp uses the same local time as the conversation',
    (tester) async {
      final utc = DateTime.utc(2026, 10, 28, 7, 14);
      final local = utc.toLocal();
      final expected =
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      await _pump(
        tester,
        ChatTile(
          chat: ChatModel(
            id: 'time',
            client: _client,
            owner: _owner,
            updatedAt: DateTime.utc(2026, 10, 28, 1, 0),
            lastMessage: ChatMessageModel(
              id: 'message',
              chatId: 'time',
              senderId: 'owner',
              content: 'Message',
              createdAt: utc,
            ),
          ),
          currentUserId: 'client',
          mode: AppMode.clientMode,
          onTap: () {},
        ),
      );
      expect(find.text(expected), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading cards fit the same narrow list in dark mode', (
    tester,
  ) async {
    await _pump(
      tester,
      const ChatTileSkeleton(index: 0),
      brightness: Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
