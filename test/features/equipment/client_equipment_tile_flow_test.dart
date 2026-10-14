import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/catalog/models/catalog_bundle.dart';
import 'package:prokat/features/catalog/models/localized_names.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_spec.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/widgets/client_equipment_tile.dart';
import 'package:prokat/features/equipment_share/widgets/share_equipment_button.dart';
import 'package:prokat/features/favorites/state/favorites_notifier.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/favorites/state/favorites_service.dart';
import 'package:prokat/features/favorites/state/favorites_state.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/user_safety/models/report_target.dart';
import 'package:prokat/features/user_safety/widgets/ugc_more_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../user_safety/user_safety_test_support.dart';

void main() {
  testWidgets('scoped card fits 320px and large text with ordered specs', (
    tester,
  ) async {
    await _pumpTile(tester, item: _equipment(startingFrom: true), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('North Kazakhstan regional district'), findsOneWidget);
    expect(find.text('long-city-slug'), findsNothing);
    expect(
      find.textContaining('No ratings yet', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('0.0'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(find.byIcon(LucideIcons.info), findsNothing);
    expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(
      find.textContaining('from ₸ 25 000', findRichText: true),
      findsOneWidget,
    );
    final photo = tester.getRect(
      find.byKey(const ValueKey('catalog-card-photo')),
    );
    final badges = tester.getRect(
      find.byKey(const ValueKey('catalog-card-badges')),
    );
    final actions = tester.getRect(
      find.byKey(const ValueKey('catalog-card-hero-actions')),
    );
    final price = tester.getRect(
      find.byKey(const ValueKey('catalog-card-price')),
    );
    expect(badges.right, lessThan(actions.left));
    expect(badges.bottom, lessThan(price.top));
    expect(photo.contains(price.bottomRight), isTrue);
    expect(find.text('First spec: One'), findsOneWidget);
    expect(find.text('Second spec: Two'), findsOneWidget);
    expect(find.text('Third spec: Yes'), findsOneWidget);
    expect(find.text('Fourth spec: Four'), findsNothing);
    expect(find.text('Private spec: Secret'), findsNothing);
    expect(find.text('Hidden spec: Hidden'), findsNothing);
    expect(
      tester.getTopLeft(find.text('First spec: One')).dy,
      lessThan(tester.getTopLeft(find.text('Second spec: Two')).dy),
    );
    expect(find.byType(ProkatFlowPrimaryButton), findsOneWidget);
    expect(find.byType(AppElevatedButton), findsNothing);
  });

  testWidgets('company actions keep share and favorite callbacks separate', (
    tester,
  ) async {
    var opens = 0;
    var shares = 0;
    final favorites = await _pumpTile(
      tester,
      item: _equipment(companyId: 'company-1', includeSpecs: false),
      company: true,
      onTap: () => opens++,
      onShare: () => shares++,
    );

    expect(find.byType(ShareEquipmentButton), findsNothing);
    expect(find.byType(UgcMoreButton), findsNothing);
    expect(
      tester.getSize(find.byType(ClientEquipmentTile)).height,
      lessThan(380),
    );
    await tester.tap(find.byIcon(LucideIcons.share2));
    await tester.tap(find.byKey(const ValueKey('catalog-card-favorite')));
    await tester.pump();
    expect(shares, 1);
    expect(favorites.calls, [('equipment-1', 'company-1')]);
    expect(opens, 0);

    await tester.ensureVisible(
      find.byKey(const ValueKey('catalog-card-details')),
    );
    await tester.tap(find.byKey(const ValueKey('catalog-card-details')));
    await tester.pump();
    expect(opens, 1);
    await tester.ensureVisible(find.text('Excavator for a long project title'));
    await tester.tap(find.text('Excavator for a long project title'));
    expect(opens, 2);
  });

  testWidgets('listing safety menu retains its equipment target and owner', (
    tester,
  ) async {
    var opens = 0;
    final item = _equipment();
    final favorites = await _pumpTile(tester, item: item, onTap: () => opens++);

    expect(
      tester
          .widget<ShareEquipmentButton>(find.byType(ShareEquipmentButton))
          .equipment,
      same(item),
    );
    final menu = tester.widget<UgcMoreButton>(find.byType(UgcMoreButton));
    expect(menu.counterpartUserId, 'owner-1');
    expect(
      menu.reportTarget,
      const ReportTarget(ReportTargetType.equipment, 'equipment-1'),
    );
    await tester.tap(find.byKey(const ValueKey('catalog-card-favorite')));
    await tester.pump();
    expect(favorites.calls, [('equipment-1', null)]);
    expect(opens, 0);

    await tester.tap(find.byKey(const ValueKey('ugc-more-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ugc-action-report')), findsOneWidget);
    expect(find.byKey(const ValueKey('ugc-action-block')), findsOneWidget);
    expect(opens, 0);
  });

  testWidgets(
    'owner offline, guest actions and draft sharing keep their rules',
    (tester) async {
      final favorites = await _pumpTile(
        tester,
        item: _equipment(online: false, status: EquipmentStatus.draft),
        signedIn: false,
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
      expect(find.byKey(const ValueKey('ugc-more-button')), findsNothing);
      expect(find.byIcon(LucideIcons.share2), findsNothing);
      final favorite = tester.widget<AppIconButton>(
        find.byKey(const ValueKey('catalog-card-favorite')),
      );
      expect(favorite.onTap, isNull);
      await tester.tap(find.byKey(const ValueKey('catalog-card-favorite')));
      expect(favorites.calls, isEmpty);
    },
  );

  testWidgets('unscoped company cards retain the legacy layout', (
    tester,
  ) async {
    await _pumpTile(
      tester,
      item: _equipment(companyId: 'company-1', city: ''),
      company: true,
      scoped: false,
    );

    expect(find.byType(ProkatFlowPrimaryButton), findsNothing);
    expect(find.byType(AppElevatedButton), findsOneWidget);
    expect(find.text('Details'), findsNothing);
    expect(find.byType(ShareEquipmentButton), findsNothing);
    expect(find.byType(UgcMoreButton), findsNothing);
    expect(find.byIcon(LucideIcons.share2), findsOneWidget);
  });
}

Future<_RecordingFavorites> _pumpTile(
  WidgetTester tester, {
  required Equipment item,
  bool company = false,
  bool scoped = true,
  bool signedIn = true,
  double textScale = 1,
  VoidCallback? onTap,
  VoidCallback? onShare,
}) async {
  await tester.binding.setSurfaceSize(const Size(320, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final favorites = _RecordingFavorites();
  Widget card = ClientEquipmentTile(
    equipment: item,
    companyCard: company,
    onTap: onTap ?? () {},
    onShare: onShare,
  );
  if (scoped) {
    card = ProkatFlowScope(palette: ProkatFlowPalette.light, child: card);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...userSafetyOverrides(FakeUserSafetyApi(), signedIn: signedIn),
        favoritesProvider.overrideWith((ref) => favorites),
        catalogProvider.overrideWith(_Catalog.new),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
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
            padding: const EdgeInsets.all(16),
            child: card,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return favorites;
}

Equipment _equipment({
  String? companyId,
  String city = 'long-city-slug',
  bool online = true,
  bool startingFrom = false,
  bool includeSpecs = true,
  EquipmentStatus status = EquipmentStatus.available,
}) => Equipment(
  id: 'equipment-1',
  companyId: companyId,
  name: 'Excavator for a long project title',
  model: 'Model',
  city: city,
  status: status,
  isVisible: true,
  owner: UserModel(
    id: 'owner-1',
    firstName: 'Owner with a long name',
    onlineStatus: online ? OwnerStatus.online : OwnerStatus.offline,
    rating: 0,
  ),
  prices: [
    PriceEntry(
      id: 'price-1',
      price: 25000,
      priceRate: parseRateOption('PER_DAY'),
      isStartingFrom: startingFrom,
    ),
  ],
  specs: [
    if (includeSpecs) ...[
      _spec('Fourth spec', 4, value: 'Four'),
      _spec('Third spec', 3, boolean: true),
      _spec('Second spec', 2, value: 'Two'),
      _spec('First spec', 1, value: 'One', iconName: 'missing-icon'),
      _spec('Private spec', 0, value: 'Secret', visible: false),
      _spec('Hidden spec', 0, value: 'Hidden', inCard: false),
    ],
  ],
);

EquipmentSpec _spec(
  String name,
  int order, {
  String? value,
  String? iconName,
  bool? boolean,
  bool visible = true,
  bool inCard = true,
}) => EquipmentSpec(
  id: name,
  name: name,
  key: name,
  unit: '',
  categoryId: 'cat-1',
  value: value,
  iconName: iconName,
  boolValue: boolean,
  sortIndex: order,
  visibleToClient: visible,
  showInCard: inCard,
);

class _Catalog extends CatalogNotifier {
  @override
  Future<CatalogBundle> build() async => const CatalogBundle(
    version: 'test',
    cities: [
      CatalogCity(
        id: 'city-1',
        slug: 'long-city-slug',
        names: LocalizedNames(en: 'North Kazakhstan regional district'),
        isVisible: true,
        acceptsEquipment: true,
        sortIndex: 0,
      ),
    ],
    categories: [],
    units: [],
    specs: [],
    specOptions: [],
    categorySpecs: [],
  );
}

class _RecordingFavorites extends FavoriteNotifier {
  final calls = <(String, String?)>[];
  _RecordingFavorites() : super(_UnusedFavoriteService());

  @override
  Future<bool> toggleFavorite(String equipmentId, {String? companyId}) async {
    calls.add((equipmentId, companyId));
    state = FavoritesState(favoritesIds: {equipmentId});
    return true;
  }
}

class _UnusedFavoriteService implements FavoriteService {
  @override
  ApiClient get apiClient => throw UnimplementedError();
  @override
  Future<ApiResponse<List<Equipment>>> getFavorites() =>
      throw UnimplementedError();
  @override
  Future<ApiResponse<void>> toggleFavorite(
    String equipmentId, {
    String? companyId,
  }) => throw UnimplementedError();
}
