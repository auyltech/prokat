import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/models/work_status.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/models/chat_model.dart';
import 'package:prokat/features/chat/widgets/booking_message_bubble.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  BookingModel booking() => BookingModel.fromJson({
    'id': 'booking-1',
    'status': 'CREATED',
    'price': 123456,
    'priceRate': 'PER_HOUR',
    'bookedOn': '2026-10-22T00:00:00',
    'bookedAt': '2026-10-22T09:30:00',
    'equipment': {
      'id': 'equipment-1',
      'name': 'Excavator with an unusually long equipment name',
      'model': 'Long model name for a narrow phone',
    },
    'location': {
      'id': 'location-1',
      'service': 'ADDRESS',
      'street': 'A very long street name near the construction site entrance',
      'houseNumber': '123/45',
      'city': 'Almaty',
      'country': 'Kazakhstan',
      'latitude': 43.25,
      'longitude': 76.95,
    },
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required BookingModel booking,
    AppMode mode = AppMode.ownerMode,
    bool flow = true,
    double textScale = 1,
  }) async {
    final card = BookingMessageBubble(
      message: const ChatMessageModel(
        id: 'message-1',
        chatId: 'chat-1',
        senderId: 'client-1',
        content: 'Request sent',
        type: 'EVENT',
        service: 'BOOKING',
      ),
      mode: mode,
      currentChat: ChatModel(id: 'chat-1', booking: booking),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: flow
                      ? ProkatFlowScope(
                          palette: ProkatFlowPalette.light,
                          child: card,
                        )
                      : card,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'pending request retains owner actions on a narrow large-text UI',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpCard(tester, booking: booking(), textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text('Request to owner'), findsOneWidget);
      expect(find.text('Request Pending'), findsOneWidget);
      expect(find.text('New Order'), findsNothing);
      expect(find.byTooltip('Reject Order'), findsOneWidget);
      expect(find.byTooltip('Propose your price'), findsOneWidget);
      expect(find.byTooltip('Accept Order'), findsOneWidget);
      expect(
        tester.getRect(find.byTooltip('Accept Order')).right,
        lessThanOrEqualTo(
          tester.getRect(find.byType(BookingMessageBubble)).right,
        ),
      );
    },
  );

  testWidgets('completed work keeps cancellation unavailable', (tester) async {
    await pumpCard(
      tester,
      booking: booking().copyWith(
        status: BookingStatus.confirmed,
        workStatus: WorkStatus.completed,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Cancel Booking'), findsNothing);
    expect(find.byTooltip('Reject Order'), findsNothing);
    expect(find.byTooltip('Accept Order'), findsNothing);
    expect(find.byTooltip('Propose your price'), findsNothing);
  });

  testWidgets('unscoped cards retain the existing presentation', (
    tester,
  ) async {
    await pumpCard(tester, booking: booking(), flow: false);

    expect(tester.takeException(), isNull);
    expect(find.text('New Order'), findsWidgets);
    expect(find.byType(BookingStatusBadge), findsOneWidget);
  });
}
