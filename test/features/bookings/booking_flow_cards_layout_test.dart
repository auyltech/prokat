import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/bookings/widgets/booking_flow_card.dart';
import 'package:prokat/features/bookings/widgets/booking_status_badge.dart';
import 'package:prokat/features/bookings/widgets/client_booking_tile.dart';
import 'package:prokat/features/bookings/widgets/owner_booking_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _street =
    'A very long delivery street near the construction site entrance';
const _comment =
    'Bring the equipment through the north entrance and wait beside the warehouse.';

BookingModel _booking(
  BookingStatus status, {
  bool company = false,
  String? reviewId,
}) => BookingModel.fromJson({
  'id': 'booking-1',
  'status': status.name.toUpperCase(),
  'price': 1250000,
  'priceRate': 'PER_HOUR',
  'bookedOn': '2026-11-02T00:00:00',
  'bookedAt': '2026-11-02T09:30:00',
  'workStatus': 'completed',
  'comment': _comment,
  'companyId': company ? 'company-1' : null,
  'chatId': 'chat-1',
  'myReviewId': reviewId,
  'owner': {
    'id': 'owner-1',
    'firstName': 'Very long owner company name for layout testing',
  },
  'client': {
    'id': 'client-1',
    'firstName': 'Very long client name for layout testing',
  },
  'equipment': company
      ? null
      : {
          'id': 'equipment-1',
          'name': 'Excavator with a long model description for a small phone',
          'model': 'Hyundai R220 LC Super',
          'plateNumber': '123 ABC 06',
        },
  'location': {
    'id': 'address-1',
    'service': 'ADDRESS',
    'street': _street,
    'houseNumber': '123/45',
    'city': 'Atyrau',
    'country': 'Kazakhstan',
    'latitude': 47.1,
    'longitude': 51.9,
  },
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> pumpCard(
    WidgetTester tester, {
    required BookingModel booking,
    bool owner = false,
    bool dark = false,
    bool flow = true,
    double textScale = 2,
    double width = 320,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tile = owner
        ? OwnerBookingTile(booking: booking)
        : ClientBookingTile(booking: booking);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: flow
                  ? ProkatFlowScope(
                      palette: dark
                          ? ProkatFlowPalette.dark
                          : ProkatFlowPalette.light,
                      child: tile,
                    )
                  : tile,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void readable(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(finder);
    expect(paragraph.didExceedMaxLines, isFalse);
    final rect = tester.getRect(finder);
    final card = tester.getRect(find.byType(BookingFlowCard));
    expect(rect.left, greaterThanOrEqualTo(card.left));
    expect(rect.right, lessThanOrEqualTo(card.right));
  }

  for (final owner in [false, true]) {
    for (final dark in [false, true]) {
      for (final status in [
        BookingStatus.created,
        BookingStatus.confirmed,
        BookingStatus.completed,
      ]) {
        testWidgets(
          'order card fits 320px/2x owner=$owner dark=$dark status=$status',
          (tester) async {
            await pumpCard(
              tester,
              booking: _booking(status),
              owner: owner,
              dark: dark,
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(BookingFlowCard), findsOneWidget);
            readable(tester, find.byKey(const ValueKey('booking-flow-price')));
            readable(tester, find.text('$_street, 123/45'));
            readable(tester, find.text(_comment));
            final l10n = AppLocalizations.of(
              tester.element(find.byType(BookingFlowCard)),
            )!;
            final hasActiveActions =
                status == BookingStatus.created ||
                status == BookingStatus.confirmed;
            expect(
              find.byTooltip(l10n.chatSection),
              hasActiveActions ? findsOneWidget : findsNothing,
            );
            expect(
              find.byTooltip(l10n.acceptOrder),
              owner && status == BookingStatus.created
                  ? findsOneWidget
                  : findsNothing,
            );
            expect(find.text(l10n.startWork), findsNothing);
            expect(find.text(l10n.completeWork), findsNothing);
            if (owner && status == BookingStatus.completed) {
              expect(find.text(l10n.submitReview), findsOneWidget);
            }
            final badge = tester.widget<BookingStatusBadge>(
              find.byType(BookingStatusBadge),
            );
            expect(badge.status, status);
          },
        );
      }
      testWidgets(
        'company order without equipment retains its content owner=$owner dark=$dark',
        (tester) async {
          await pumpCard(
            tester,
            booking: _booking(BookingStatus.confirmed, company: true),
            owner: owner,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Order comment'), findsOneWidget);
          readable(tester, find.text(_comment));
          readable(tester, find.byKey(const ValueKey('booking-flow-price')));
        },
      );
    }
  }

  testWidgets('client history retains its existing review eligibility', (
    tester,
  ) async {
    await pumpCard(
      tester,
      booking: _booking(BookingStatus.completed, reviewId: 'review-1'),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(BookingFlowCard)),
    )!;
    expect(find.byTooltip(l10n.submitReview), findsOneWidget);
    expect(find.byTooltip(l10n.chatSection), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screens outside Flow retain their previous card presentation', (
    tester,
  ) async {
    await pumpCard(
      tester,
      booking: _booking(BookingStatus.confirmed),
      flow: false,
      textScale: 1,
      width: 800,
    );
    expect(find.byType(BookingFlowCard), findsNothing);
    expect(find.byType(BookingStatusBadge), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
