import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_profile_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/price_negotiations/models/price_negotiation_model.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_notifier.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_service.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_proposal_card.dart';
import 'package:prokat/features/price_negotiations/widgets/booking_terms_summary.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _updatedAt = '2026-10-28T07:30:00.123Z';
const _currentEnglish =
    'Original construction entrance near the administration building and the long service road';
const _proposedEnglish =
    'New delivery entrance on the opposite side of the industrial site, loading gate number seven';
const _currentRussian =
    'Текущий въезд на строительную площадку у административного корпуса / Original construction entrance';
const _proposedRussian =
    'Новый въезд с противоположной стороны промышленной площадки / New delivery entrance';

Map<String, dynamic> _location({required bool proposed}) => {
  'street': proposed ? _proposedEnglish : _currentEnglish,
  'streetNames': {
    'en': proposed ? _proposedEnglish : _currentEnglish,
    'ru': proposed ? _proposedRussian : _currentRussian,
  },
  'houseNumber': proposed ? '116/2' : '101/4',
  'city': 'Atyrau',
  'cityNames': {'en': 'Atyrau', 'ru': 'Атырау'},
  'country': 'Kazakhstan',
  'latitude': proposed ? 47.2 : 47.1,
  'longitude': proposed ? 51.8 : 51.9,
};

PriceNegotiation _proposal({
  String status = 'CREATED',
  int version = 1,
  bool withUpdatedAt = true,
}) => PriceNegotiation.fromJson({
  'id': 'terms-proposal-1',
  'bookingId': 'booking-1',
  'createdById': 'other-party',
  'price': 17000,
  'priceRate': 'PER_HOUR',
  'status': status,
  'comment': 'Please use the new loading entrance.',
  if (withUpdatedAt) 'updatedAt': _updatedAt,
  'requiresTermsAcknowledgement': true,
  'proposedTerms': {
    'version': version,
    'bookedOn': '2026-11-02T00:00:00Z',
    'bookedAt': '2026-11-02T09:30:00Z',
    'location': _location(proposed: true),
    'previous': {
      'price': 18000,
      'priceRate': 'PER_HOUR',
      'bookedOn': '2026-11-01T00:00:00Z',
      'bookedAt': '2026-11-01T08:00:00Z',
      'location': _location(proposed: false),
    },
  },
});

class _UnusedService implements PriceNegotiationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Mutation extends PriceNegotiationMutationNotifier {
  _Mutation(Ref ref) : super(ref, _UnusedService());
  final responses = <Map<String, dynamic>>[];
  final withdrawals = <String>[];

  @override
  Future<void> respondToPriceNegotiation({
    required String negotiationId,
    required PriceNegotiationResponse response,
    String? bookingId,
    String? offerId,
    String? chatId,
    int? acceptedTermsVersion,
    DateTime? expectedNegotiationUpdatedAt,
  }) async {
    responses.add({
      'negotiationId': negotiationId,
      'response': response,
      'bookingId': bookingId,
      'offerId': offerId,
      'chatId': chatId,
      'acceptedTermsVersion': acceptedTermsVersion,
      'expectedNegotiationUpdatedAt': expectedNegotiationUpdatedAt,
    });
  }

  @override
  Future<void> cancelPriceNegotiation(
    String negotiationId, {
    String? bookingId,
    String? offerId,
    String? chatId,
  }) async {
    withdrawals.add(negotiationId);
  }
}

class _FixedOwnerProfile extends OwnerProfileNotifier {
  _FixedOwnerProfile(this.initialStatus);
  final OwnerStatus initialStatus;

  @override
  Future<OwnerProfileModel?> build() async =>
      OwnerProfileModel(onlineStatus: initialStatus);

  void completeGoOnline() {
    state = AsyncData(OwnerProfileModel(onlineStatus: OwnerStatus.online));
  }
}

void main() {
  Future<_Mutation> pumpCard(
    WidgetTester tester, {
    required PriceNegotiation proposal,
    bool dark = false,
    double textScale = 1,
    Locale locale = const Locale('en'),
    bool isMe = false,
    AppMode mode = AppMode.clientMode,
    OwnerStatus? ownerStatus,
  }) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late _Mutation mutation;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (ownerStatus != null)
            ownerProfileProvider.overrideWith(
              () => _FixedOwnerProfile(ownerStatus),
            ),
          priceNegotiationMutationProvider.overrideWith(
            (ref) => mutation = _Mutation(ref),
          ),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: BookingTermsProposalCard(
                proposal: proposal,
                isMe: isMe,
                chatId: 'chat-1',
                mode: mode,
              ),
            ),
          ),
        ),
      ),
    );
    if (ownerStatus != null) {
      await ProviderScope.containerOf(
        tester.element(find.byType(BookingTermsProposalCard)),
      ).read(ownerProfileProvider.future);
    }
    await tester.pumpAndSettle();
    return mutation;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder.hitTestable());
    await tester.pumpAndSettle();
  }

  Finder filledButton(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget is FilledButton),
  );

  Finder outlinedButton(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      for (final language in ['en', 'ru']) {
        testWidgets(
          'full address comparison fits 320px, $language, scale $scale, dark $dark',
          (tester) async {
            await pumpCard(
              tester,
              proposal: _proposal(),
              dark: dark,
              textScale: scale,
              locale: Locale(language),
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(BookingTermsSummary), findsNWidgets(2));
            final context = tester.element(
              find.byType(BookingTermsProposalCard),
            );
            final l10n = AppLocalizations.of(context)!;
            expect(find.text(l10n.currentOrderTerms), findsOneWidget);
            expect(find.text(l10n.proposedOrderTerms), findsOneWidget);
            final oldStreet = language == 'ru'
                ? _currentRussian
                : _currentEnglish;
            final newStreet = language == 'ru'
                ? _proposedRussian
                : _proposedEnglish;
            final city = language == 'ru' ? 'Атырау' : 'Atyrau';
            for (final address in [
              '$oldStreet, 101/4, $city',
              '$newStreet, 116/2, $city',
            ]) {
              final text = find.text(address);
              expect(text, findsOneWidget);
              expect(tester.widget<Text>(text).maxLines, isNull);
              expect(
                tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
                isFalse,
              );
              expect(tester.getRect(text).right, lessThanOrEqualTo(308));
            }
            final accept = filledButton(l10n.acceptOrderTerms);
            await tester.ensureVisible(accept);
            await tester.pumpAndSettle();
            expect(accept.hitTestable(), findsOneWidget);
            expect(tester.getRect(accept).left, greaterThanOrEqualTo(12));
            expect(tester.getRect(accept).right, lessThanOrEqualTo(308));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('counterpart consent sends the exact displayed terms version', (
    tester,
  ) async {
    final proposal = _proposal();
    final mutation = await pumpCard(tester, proposal: proposal);
    await tapVisible(tester, filledButton('Accept terms'));
    expect(mutation.responses, hasLength(1));
    expect(mutation.responses.single, {
      'negotiationId': proposal.id,
      'response': PriceNegotiationResponse.accept,
      'bookingId': proposal.bookingId,
      'offerId': null,
      'chatId': 'chat-1',
      'acceptedTermsVersion': 1,
      'expectedNegotiationUpdatedAt': DateTime.parse(_updatedAt),
    });
  });

  testWidgets(
    'offline owner cannot consent and going online requires a new consent tap',
    (tester) async {
      final mutation = await pumpCard(
        tester,
        proposal: _proposal(),
        mode: AppMode.ownerMode,
        ownerStatus: OwnerStatus.offline,
      );
      final cardContext = tester.element(find.byType(BookingTermsProposalCard));
      final l10n = AppLocalizations.of(cardContext)!;
      await tapVisible(tester, filledButton(l10n.acceptOrderTerms));
      expect(
        find.text(l10n.ownerOfflineMustBeOnlineToAcceptOrder),
        findsOneWidget,
      );
      expect(mutation.responses, isEmpty);

      // Simulate the existing online sheet's successful completion, without
      // invoking its billing/equipment/network dependencies in this card test.
      final profile = ProviderScope.containerOf(
        cardContext,
      ).read(ownerProfileProvider.notifier) as _FixedOwnerProfile;
      profile.completeGoOnline();
      Navigator.of(cardContext, rootNavigator: true).pop(true);
      await tester.pumpAndSettle();
      expect(mutation.responses, isEmpty);
      expect(
        find.text(l10n.ownerOfflineMustBeOnlineToAcceptOrder),
        findsNothing,
      );

      await tapVisible(tester, filledButton(l10n.acceptOrderTerms));
      expect(mutation.responses, hasLength(1));
      expect(
        mutation.responses.single['response'],
        PriceNegotiationResponse.accept,
      );
      expect(mutation.responses.single['acceptedTermsVersion'], 1);
      expect(
        mutation.responses.single['expectedNegotiationUpdatedAt'],
        DateTime.parse(_updatedAt),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('already online owner sends exact displayed consent once', (
    tester,
  ) async {
    final proposal = _proposal();
    final mutation = await pumpCard(
      tester,
      proposal: proposal,
      mode: AppMode.ownerMode,
      ownerStatus: OwnerStatus.online,
    );
    await tapVisible(tester, filledButton('Accept terms'));
    expect(mutation.responses, hasLength(1));
    expect(mutation.responses.single, {
      'negotiationId': proposal.id,
      'response': PriceNegotiationResponse.accept,
      'bookingId': proposal.bookingId,
      'offerId': null,
      'chatId': 'chat-1',
      'acceptedTermsVersion': 1,
      'expectedNegotiationUpdatedAt': DateTime.parse(_updatedAt),
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown terms version cannot be accepted but can be rejected', (
    tester,
  ) async {
    final mutation = await pumpCard(tester, proposal: _proposal(version: 2));
    expect(find.text('Update the app to confirm these terms.'), findsOneWidget);
    final accept = filledButton('Accept terms');
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    expect(find.byType(BookingTermsSummary), findsNothing);
    await tapVisible(tester, outlinedButton('Reject'));
    expect(
      mutation.responses.single['response'],
      PriceNegotiationResponse.reject,
    );
    expect(mutation.responses.single['acceptedTermsVersion'], isNull);
    expect(mutation.responses.single['expectedNegotiationUpdatedAt'], isNull);
  });

  testWidgets('missing proposal revision disables consent', (tester) async {
    final mutation = await pumpCard(
      tester,
      proposal: _proposal(withUpdatedAt: false),
    );
    expect(
      tester.widget<FilledButton>(filledButton('Accept terms')).onPressed,
      isNull,
    );
    expect(mutation.responses, isEmpty);
  });

  for (final status in ['ACCEPTED', 'REJECTED']) {
    testWidgets('$status history preserves the comparison without actions', (
      tester,
    ) async {
      final mutation = await pumpCard(
        tester,
        proposal: _proposal(status: status),
      );
      expect(find.byType(BookingTermsSummary), findsNWidgets(2));
      expect(
        find.byWidgetPredicate((widget) => widget is FilledButton),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate((widget) => widget is OutlinedButton),
        findsNothing,
      );
      expect(mutation.responses, isEmpty);
      expect(mutation.withdrawals, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('author can withdraw but cannot accept their own proposal', (
    tester,
  ) async {
    final mutation = await pumpCard(tester, proposal: _proposal(), isMe: true);
    expect(filledButton('Accept terms'), findsNothing);
    expect(outlinedButton('Reject'), findsNothing);
    await tapVisible(tester, outlinedButton('Withdraw proposal'));
    expect(mutation.withdrawals, ['terms-proposal-1']);
    expect(mutation.responses, isEmpty);
  });
}
