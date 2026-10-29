import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_flow_card.dart';
import 'package:prokat/features/requests/widgets.dart/owner_request_tile.dart';
import 'package:prokat/features/user/widgets/user_info_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../user_safety/user_safety_test_support.dart';

const _client = UserModel(
  id: 'client',
  firstName: 'Клиент с очень длинным именем и фамилией',
  rating: 4.9,
  orderCount: 123,
);
const _street = 'Очень длинная улица рядом со строительной площадкой';
const _capacity = 'Вывоз грунта и подготовка строительной площадки, 25 тонн';
const _comment = 'Сначала нужно согласовать подъезд к объекту и объём работ.';
const _category = Category(
  id: 'category',
  name: 'Автокраны и подъёмная техника',
  sortIndex: 0,
);

RequestModel _request({
  bool priced = true,
  bool address = true,
  PriceRateOption? rate,
  DateTime? createdAt,
}) => RequestModel(
  id: 'request-1',
  status: RequestStatus.created,
  capacity: _capacity,
  offeredPrice: priced ? 1250000 : 0,
  offeredPriceRate: rate,
  category: _category,
  client: _client,
  comment: _comment,
  requiredOn: DateTime(2026, 11, 2),
  requiredAt: DateTime(2026, 11, 2, 9, 30),
  createdAt: createdAt ?? DateTime.now(),
  location: address
      ? LocationModel(
          service: 'ADDRESS',
          street: _street,
          houseNumber: '116',
          city: 'Атырау',
          country: 'Казахстан',
          latitude: 47.1,
          longitude: 51.9,
        )
      : null,
);

Widget _card(
  RequestModel request, {
  bool offered = false,
  VoidCallback? hide,
  VoidCallback? send,
  VoidCallback? chat,
  VoidCallback? view,
  VoidCallback? location,
}) => OwnerRequestFlowCard(
  request: request,
  requestState: offered
      ? OwnerRequestState.offerSent
      : OwnerRequestState.newRequest,
  lifetimeLabel: '23 часа осталось',
  clientSummary: const UserInfoTile(user: _client),
  moreAction: IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
  hasActiveOffer: offered,
  onHide: hide ?? () {},
  onSend: send ?? () {},
  onChat: chat ?? () {},
  onViewOffer: view ?? () {},
  onLocation: location,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double scale = 2,
}) async {
  tester.view.physicalSize = const Size(320, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final palette = dark ? ProkatFlowPalette.dark : ProkatFlowPalette.light;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(guestAuth)],
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, appChild) => ProkatFlowScope(
          palette: palette,
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: appChild!,
          ),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final dark in [false, true]) {
    for (final offered in [false, true]) {
      for (final priced in [false, true]) {
        testWidgets(
          'incoming request fits 320px/2x: dark $dark, offer $offered, priced $priced',
          (tester) async {
            await _pump(
              tester,
              _card(_request(priced: priced), offered: offered),
              dark: dark,
            );
            expect(tester.takeException(), isNull);
            expect(find.text(_category.name), findsOneWidget);
            expect(find.text(_capacity), findsOneWidget);
            expect(find.text('$_street, 116'), findsOneWidget);
            expect(find.text(_comment), findsOneWidget);
            final budget = tester.widget<Text>(
              find.byKey(const ValueKey('owner-request-budget')),
            );
            expect(budget.maxLines, isNull);
            expect(
              budget.data,
              priced ? contains('1 250 000') : isNot(contains('1 250 000')),
            );
            // This DTO has no rate: never invent a per-hour budget.
            expect(budget.data, isNot(contains('/')));
            final primary = find.byType(ProkatFlowPrimaryButton);
            await tester.ensureVisible(primary);
            await tester.pumpAndSettle();
            expect(primary.hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('send and hide preserve distinct callbacks', (tester) async {
    var sent = 0;
    var hidden = 0;
    await _pump(
      tester,
      _card(_request(), send: () => sent++, hide: () => hidden++),
      scale: 1,
    );
    await tester.ensureVisible(find.byType(ProkatFlowPrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProkatFlowPrimaryButton));
    await tester.tap(find.byType(ProkatFlowIconButton));
    expect(sent, 1);
    expect(hidden, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an existing offer exposes chat and offer details, not another send',
    (tester) async {
      var chatted = 0;
      var viewed = 0;
      var sent = 0;
      await _pump(
        tester,
        _card(
          _request(),
          offered: true,
          chat: () => chatted++,
          view: () => viewed++,
          send: () => sent++,
        ),
        scale: 1,
      );
      await tester.ensureVisible(find.byType(ProkatFlowPrimaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ProkatFlowPrimaryButton));
      await tester.tap(find.byType(ProkatFlowIconButton));
      expect(chatted, 1);
      expect(viewed, 1);
      expect(sent, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing address stays readable and has no location action', (
    tester,
  ) async {
    await _pump(tester, _card(_request(address: false)));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OwnerRequestFlowCard)),
    )!;
    final value = find.text(l10n.unknownLocation);
    expect(value, findsOneWidget);
    final target = find.ancestor(of: value, matching: find.byType(InkWell));
    expect(tester.widget<InkWell>(target).onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a known budget unit is preserved', (tester) async {
    await _pump(
      tester,
      _card(
        _request(
          rate: const PriceRateOption(value: 'PER_HOUR', label: 'hour'),
        ),
      ),
    );
    final budget = tester.widget<Text>(
      find.byKey(const ValueKey('owner-request-budget')),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(OwnerRequestFlowCard)),
    )!;
    expect(budget.data, contains(l10n.perHour));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expired tenders remain absent from the tile', (tester) async {
    await _pump(
      tester,
      OwnerRequestTile(
        request: _request(
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
        ),
        offers: const [],
      ),
    );
    expect(find.byType(OwnerRequestFlowCard), findsNothing);
    expect(find.byType(ProkatFlowPrimaryButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
