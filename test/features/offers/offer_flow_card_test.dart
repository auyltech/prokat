import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_status.dart';
import 'package:prokat/features/offers/widgets/offer_flow_card.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'large text fits and an unreviewed owner has no zero-star rating',
    (tester) async {
      await _pump(tester, _card(), scale: 2);
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('No ratings yet', findRichText: true),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.textContaining('0.0'), findsNothing);
      expect(find.text('₸ 22 000'), findsOneWidget);
      expect(find.textContaining('Hyundai R220'), findsOneWidget);
      expect(find.text('Can arrive at 08:30'), findsOneWidget);
    },
  );

  testWidgets('chat, accept and reject keep separate callbacks', (
    tester,
  ) async {
    var chat = 0, accept = 0, reject = 0;
    await _pump(
      tester,
      _card(
        onChat: () => chat++,
        onAccept: () => accept++,
        onReject: () => reject++,
      ),
    );
    await tester.tap(find.byTooltip('Chat'));
    await tester.tap(find.text('Accept'));
    await tester.tap(find.text('Reject'));
    expect([chat, accept, reject], [1, 1, 1]);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets(
    'submitting disables mutations while existing chat remains usable',
    (tester) async {
      var chat = 0, mutations = 0;
      await _pump(
        tester,
        _card(
          submitting: true,
          onChat: () => chat++,
          onAccept: () => mutations++,
          onReject: () => mutations++,
        ),
      );
      await tester.tap(find.byTooltip('Chat'));
      await tester.tap(find.text('Reject'));
      expect(chat, 1);
      expect(mutations, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('handled offer retains chat but cannot be accepted or rejected', (
    tester,
  ) async {
    await _pump(tester, _card(status: OfferStatus.accepted, best: false));
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(find.byTooltip('Chat'), findsOneWidget);
  });
}

OfferFlowCard _card({
  OfferStatus status = OfferStatus.created,
  bool submitting = false,
  bool best = true,
  VoidCallback? onChat,
  VoidCallback? onAccept,
  VoidCallback? onReject,
}) => OfferFlowCard(
  offer: OfferModel(
    id: 'offer',
    status: status,
    requestId: 'request',
    chatId: 'chat',
    equipmentId: 'equipment',
    price: 22000,
    priceRate: priceRateOptions.last,
    owner: const UserModel(
      companyName: 'Long company name of a private owner',
      role: UserRole.company,
    ),
    equipment: EquipmentSummaryModel(
      name: 'Tracked excavator',
      model: 'Hyundai R220',
    ),
    comment: 'Can arrive at 08:30',
  ),
  avatar: const CircleAvatar(radius: 24, child: Text('AC')),
  isBestPrice: best,
  submitting: submitting,
  unreadCount: 120,
  onChat: onChat ?? () {},
  onAccept: onAccept ?? () {},
  onReject: onReject ?? () {},
);

Future<void> _pump(WidgetTester tester, Widget card, {double scale = 1}) async {
  tester.view.physicalSize = const Size(320, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(12), child: card),
        ),
      ),
    ),
  );
  await tester.pump();
}
