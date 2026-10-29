import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/notifiers/current_chat_notifier.dart';
import 'package:prokat/features/chat/providers/current_chat_provider.dart';
import 'package:prokat/features/chat/widgets/chat_booking_terms_sheet.dart';
import 'package:prokat/features/chat/widgets/inquiry_context_card.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiations_query_notifier.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../user_safety/user_safety_test_support.dart';

const _title =
    'Экскаватор-погрузчик для строительной площадки / Backhoe loader for construction work';
const _contextKey = ValueKey('inquiry-context-card');
const _titleKey = ValueKey('inquiry-context-title');
const _statusKey = ValueKey('inquiry-context-status');
const _scheduleKey = ValueKey('inquiry-context-schedule');
const _priceKey = ValueKey('inquiry-context-price');

final _equipment = Equipment.fromJson({
  'id': 'equipment-1',
  'name': _title,
  'model': 'JCB 3CX Super',
  'status': 'AVAILABLE',
  'isVisible': true,
  'prices': [],
});

ChatModel _discussion({ChatStatus status = ChatStatus.active}) => ChatModel(
  id: 'chat-1',
  status: status,
  inquiryEquipmentId: _equipment.id,
  inquiryEquipment: _equipment,
);

ChatModel _bookingChat() => ChatModel(
  id: 'chat-1',
  bookingId: 'booking-1',
  booking: BookingModel(
    id: 'booking-1',
    status: BookingStatus.confirmed,
    price: 1250000,
    priceRate: const PriceRateOption(value: 'PER_HOUR', label: 'Per hour'),
    bookedOn: DateTime(2026, 11, 2),
    bookedAt: DateTime(2026, 11, 2, 9, 30),
    equipment: EquipmentSummaryModel(
      id: _equipment.id,
      name: _title,
      model: 'JCB 3CX Super',
    ),
  ),
);

class _CurrentChat extends CurrentChatNotifier {
  final ChatModel chat;
  _CurrentChat(this.chat);

  @override
  Future<ChatModel?> build(String chatId) async => chat;
}

class _EmptyProposals extends PriceNegotiationsNotifier {
  @override
  Future<QueryState<PriceNegotiation>> build(PriceNegotiationQuery arg) async =>
      const QueryState(itemsPerPage: 20, count: 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> pumpCard(
    WidgetTester tester, {
    required ChatModel chat,
    AppMode mode = AppMode.clientMode,
    VoidCallback? onSetTerms,
    bool dark = false,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final query = priceNegotiationQueryFor(bookingId: chat.bookingId);
    final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(signedInAuth),
          currentChatProvider.overrideWith(() => _CurrentChat(chat)),
          if (query != null)
            priceNegotiationsProvider.overrideWith(_EmptyProposals.new),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => ProkatFlowScope(
            palette: palette,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: InquiryContextCard(
                chat: chat,
                mode: mode,
                onSetTerms: onSetTerms,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectReadable(WidgetTester tester, Finder finder) {
    final text = tester.widget<Text>(finder);
    expect(text.maxLines, isNull);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    final paragraph = tester.renderObject<RenderParagraph>(finder);
    expect(paragraph.didExceedMaxLines, isFalse);
    final bounds = tester.getRect(finder);
    expect(bounds.left, greaterThanOrEqualTo(12));
    expect(bounds.right, lessThanOrEqualTo(308.1));
  }

  for (final dark in [false, true]) {
    for (final language in ['en', 'ru']) {
      for (final kind in ['booking', 'client inquiry', 'owner inquiry']) {
        testWidgets('$kind fits 320px at 2x text, $language, dark $dark', (
          tester,
        ) async {
          final isBooking = kind == 'booking';
          final isClient = kind == 'client inquiry';
          await pumpCard(
            tester,
            chat: isBooking ? _bookingChat() : _discussion(),
            mode: kind == 'owner inquiry'
                ? AppMode.ownerMode
                : AppMode.clientMode,
            onSetTerms: isClient ? () {} : null,
            dark: dark,
            textScale: 2,
            locale: Locale(language),
          );
          expect(tester.takeException(), isNull);
          final palette = dark
              ? ProkatFlowPalette.dark
              : ProkatFlowPalette.light;
          final title = tester.widget<Text>(find.byKey(_titleKey));
          expect(title.data, _title);
          expect(title.maxLines, 2);
          expect(title.style?.color, palette.title);
          expectReadable(tester, find.byKey(_statusKey));
          if (isBooking) {
            expect(
              find.byKey(const ValueKey('inquiry-close-button')),
              findsNothing,
            );
            expectReadable(tester, find.byKey(_scheduleKey));
            expectReadable(tester, find.byKey(_priceKey));
            expect(
              tester.widget<Text>(find.byKey(_scheduleKey)).data,
              contains('09:30'),
            );
            expect(
              tester
                  .widget<Text>(find.byKey(_priceKey))
                  .textSpan
                  ?.toPlainText(),
              contains('1 250 000'),
            );
            // The tariff must never take the title's horizontal space.
            expect(
              tester.getSize(find.byKey(_titleKey)).width,
              greaterThan(170),
            );
            expect(
              tester.widget<Text>(find.byKey(_statusKey)).style?.color,
              palette.success,
            );
          } else {
            expect(
              find.byKey(const ValueKey('inquiry-close-button')),
              findsOneWidget,
            );
            expect(find.byKey(_priceKey), findsNothing);
            if (isClient) {
              final l10n = AppLocalizations.of(
                tester.element(find.byType(InquiryContextCard)),
              )!;
              expectReadable(tester, find.text(l10n.inquiryCreateOrder));
            }
          }
        });
      }
    }
  }

  testWidgets('client opens inquiry terms without creating an order', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var calls = 0;
      final chat = _discussion();
      await pumpCard(tester, chat: chat, onSetTerms: () => calls++);
      final node = tester.getSemantics(find.byKey(_contextKey));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.label, contains('Set order terms'));
      await tester.tap(find.byKey(_titleKey));
      await tester.pump();
      expect(calls, 1);
      expect(chat.bookingId, isNull);
      expect(chat.booking, isNull);
      expect(find.byType(ChatBookingTermsSheet), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('owner inquiry has no terms action without the client callback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpCard(tester, chat: _discussion(), mode: AppMode.ownerMode);
      expect(find.text('Set order terms'), findsNothing);
      final node = tester.getSemantics(find.byKey(_contextKey));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      await tester.tap(find.byKey(_titleKey));
      await tester.pumpAndSettle();
      expect(find.byType(ChatBookingTermsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'booking context exposes a labeled tap and opens the terms sheet',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpCard(tester, chat: _bookingChat(), mode: AppMode.ownerMode);
        final node = tester.getSemantics(find.byKey(_contextKey));
        expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(node.label, contains('Order terms'));
        await tester.tap(find.byKey(_titleKey));
        await tester.pumpAndSettle();
        final sheet = tester.widget<ChatBookingTermsSheet>(
          find.byType(ChatBookingTermsSheet),
        );
        expect(sheet.mode, AppMode.ownerMode);
        expect(sheet.chat.bookingId, 'booking-1');
        expect(find.text('Order terms'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
