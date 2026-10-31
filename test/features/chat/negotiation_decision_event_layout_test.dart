import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/features/bookings/models/query_state.dart';
import 'package:prokat/features/chat/models/chat_message_model.dart';
import 'package:prokat/features/chat/widgets/negotiation_message_bubble.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_query.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_status.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiations_query_notifier.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_proposal_card.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_summary.dart';
import 'package:prokat/features/price_negotiations/widgets/price_negotiation_status_badge.dart';
import 'package:prokat/l10n/app_localizations.dart';

Map<String, dynamic> _proposal(String status) {
  const location = {
    'street': 'Construction entrance',
    'city': 'Atyrau',
    'country': 'Kazakhstan',
    'latitude': 47.1,
    'longitude': 51.9,
  };
  return {
    'id': 'proposal-1',
    'bookingId': 'booking-1',
    'createdById': 'client-1',
    'status': status,
    'price': 17000,
    'priceRate': 'PER_HOUR',
    'updatedAt': status == 'CREATED'
        ? '2026-10-29T07:30:00Z'
        : '2026-10-29T08:00:00Z',
    'requiresTermsAcknowledgement': true,
    'proposedTerms': {
      'version': 1,
      'bookedOn': '2026-11-02T00:00:00Z',
      'bookedAt': '2026-11-02T09:30:00Z',
      'location': location,
      'previous': {
        'price': 18000,
        'priceRate': 'PER_HOUR',
        'bookedOn': '2026-11-01T00:00:00Z',
        'bookedAt': '2026-11-01T08:00:00Z',
        'location': location,
      },
    },
  };
}

class _UnusedService implements PriceNegotiationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CanonicalRows extends PriceNegotiationsNotifier {
  _CanonicalRows(this.row, this.onRead);
  final PriceNegotiation row;
  final VoidCallback onRead;
  @override
  Future<QueryState<PriceNegotiation>> build(PriceNegotiationQuery arg) async {
    onRead();
    return QueryState(items: [row], count: 1, itemsPerPage: 20);
  }
}

void main() {
  Future<void> pumpMessage(
    WidgetTester tester, {
    required String eventStatus,
    required String canonicalStatus,
    required VoidCallback onRead,
    bool dark = false,
  }) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priceNegotiationsProvider.overrideWith(
            () => _CanonicalRows(
              PriceNegotiation.fromJson(_proposal(canonicalStatus)),
              onRead,
            ),
          ),
          priceNegotiationMutationProvider.overrideWith(
            (ref) => PriceNegotiationMutationNotifier(ref, _UnusedService()),
          ),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ProkatFlowScope(
            palette: palette,
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: NegotiationMessageBubble(
                  isMe: false,
                  message: ChatMessageModel(
                    id: 'event-1',
                    chatId: 'chat-1',
                    senderId: 'owner-1',
                    content: '',
                    type: 'EVENT',
                    service: 'NEGOTIATION',
                    meta: _proposal(eventStatus),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'original proposal keeps full comparison after acceptance, dark=$dark',
      (tester) async {
        var reads = 0;
        await pumpMessage(
          tester,
          eventStatus: 'CREATED',
          canonicalStatus: 'ACCEPTED',
          onRead: () => reads++,
          dark: dark,
        );
        expect(reads, 1);
        expect(find.byType(BookingTermsProposalCard), findsOneWidget);
        expect(find.byType(BookingTermsSummary), findsNWidgets(2));
        expect(
          find.byKey(const ValueKey('terms-decision-event')),
          findsNothing,
        );
        expect(
          tester
              .widget<PriceNegotiationStatusBadge>(
                find.byType(PriceNegotiationStatusBadge),
              )
              .status,
          PriceNegotiationStatus.accepted,
        );
        expect(
          find.byWidgetPredicate(
            (widget) => widget is FilledButton || widget is OutlinedButton,
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    for (final status in ['ACCEPTED', 'REJECTED', 'CANCELLED']) {
      testWidgets(
        '$status event is compact at320px/2x even with stale canonical row, dark=$dark',
        (tester) async {
          var reads = 0;
          await pumpMessage(
            tester,
            eventStatus: status,
            canonicalStatus: 'CREATED',
            onRead: () => reads++,
            dark: dark,
          );
          expect(reads, 0);
          expect(
            find.byKey(const ValueKey('terms-decision-event')),
            findsOneWidget,
          );
          expect(find.byType(BookingTermsProposalCard), findsNothing);
          expect(find.byType(BookingTermsSummary), findsNothing);
          final badge = find.byType(PriceNegotiationStatusBadge);
          expect(
            tester.widget<PriceNegotiationStatusBadge>(badge).status,
            parsePriceNegotiationStatus(status),
          );
          final context = tester.element(find.byType(NegotiationMessageBubble));
          final title = find.text(
            AppLocalizations.of(context)!.orderTermsProposalTitle,
          );
          expect(title, findsOneWidget);
          expect(
            tester.renderObject<RenderParagraph>(title).didExceedMaxLines,
            isFalse,
          );
          final card = tester.getRect(
            find.byKey(const ValueKey('terms-decision-event')),
          );
          expect(card.left, greaterThanOrEqualTo(12));
          expect(card.right, lessThanOrEqualTo(308));
          expect(
            find.byWidgetPredicate(
              (widget) => widget is FilledButton || widget is OutlinedButton,
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
