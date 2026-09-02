import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/favorites/state/favorites_notifier.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/favorites/state/favorites_service.dart';
import 'package:prokat/features/favorites/state/favorites_state.dart';
import 'package:prokat/features/favorites/widgets/favorite_item_tile.dart';
import 'package:prokat/features/favorites/widgets/favorites_section.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hides the drawer when there are no favorites', (tester) async {
    await _pumpOverlay(tester, favorites: const []);

    expect(find.text('Мои избранные'), findsNothing);
    expect(find.byKey(const Key('favorites-section-header')), findsNothing);
    expect(find.text('Смотреть все'), findsNothing);
  });

  testWidgets('shows a collapsed strip when favorites exist', (tester) async {
    await _pumpOverlay(tester, favorites: [_equipment('1')]);

    expect(find.text('Мои избранные'), findsOneWidget);
    expect(find.text('Смотреть все'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(_drawerHeight(tester), FavoritesOverlay.collapsedHeight);
  });

  testWidgets('header tap expands the row and rotates the chevron', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      favorites: [_equipment('1'), _equipment('2'), _equipment('3')],
    );

    await tester.tap(find.byKey(const Key('favorites-section-header')));
    await tester.pumpAndSettle();

    expect(_drawerHeight(tester), FavoritesOverlay.expandedHeight);
    expect(find.byType(FavoriteItemTile), findsWidgets);

    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(rotation.turns, 0.5);
  });

  testWidgets('header tap collapses the expanded drawer', (tester) async {
    await _pumpOverlay(tester, favorites: [_equipment('1'), _equipment('2')]);

    await tester.tap(find.byKey(const Key('favorites-section-header')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('favorites-section-header')));
    await tester.pumpAndSettle();

    expect(_drawerHeight(tester), FavoritesOverlay.collapsedHeight);

    final rotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(rotation.turns, 0);
  });

  testWidgets('scrolling the catalog collapses the drawer', (tester) async {
    await _pumpOverlay(
      tester,
      favorites: List.generate(6, (i) => _equipment('$i')),
    );

    await tester.tap(find.byKey(const Key('favorites-section-header')));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Catalog item'), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(_drawerHeight(tester), FavoritesOverlay.collapsedHeight);
  });

  testWidgets('scrolling the favorites row does not collapse the drawer', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      favorites: List.generate(8, (i) => _equipment('$i')),
    );

    await tester.tap(find.byKey(const Key('favorites-section-header')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('favorites-section-list')),
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();

    expect(_drawerHeight(tester), FavoritesOverlay.expandedHeight);
  });

  testWidgets('tapping the catalog collapses the drawer', (tester) async {
    await _pumpOverlay(tester, favorites: [_equipment('1')]);

    await tester.tap(find.byKey(const Key('favorites-section-header')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catalog item'));
    await tester.pumpAndSettle();

    expect(_drawerHeight(tester), FavoritesOverlay.collapsedHeight);
  });

  testWidgets('view all opens favorites without expanding the drawer', (
    tester,
  ) async {
    await _pumpOverlay(tester, favorites: [_equipment('1')]);

    await tester.tap(find.text('Смотреть все'));
    await tester.pumpAndSettle();

    expect(find.text('Full favorites'), findsOneWidget);
    expect(find.byKey(const Key('favorites-section-list')), findsNothing);
  });

  testWidgets('heart counter shows 9+ when there are more than 9 favorites', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      favorites: List.generate(10, (i) => _equipment('$i')),
    );

    expect(find.text('9+'), findsOneWidget);
    expect(find.text('10'), findsNothing);
  });

  testWidgets('heart counter shows 9 when there are exactly 9 favorites', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      favorites: List.generate(9, (i) => _equipment('$i')),
    );

    expect(find.text('9'), findsOneWidget);
    expect(find.text('9+'), findsNothing);
  });

  testWidgets('expanded cards show the equipment price instead of POA', (
    tester,
  ) async {
    await _pumpOverlay(
      tester,
      favorites: [
        _equipment(
          '1',
          prices: [
            PriceEntry(
              id: 'price-1',
              price: 1500,
              priceRate: parseRateOption('PER_CUBIC_METER'),
            ),
          ],
          owner: const UserModel(
            firstName: 'Ерлан',
            lastName: 'Садыков',
            rating: 5,
            orderCount: 21,
          ),
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('favorites-section-header')));
    await tester.pumpAndSettle();

    expect(find.textContaining('1,500'), findsOneWidget);
    expect(find.text('ПОЗ'), findsNothing);
    expect(find.text('5'), findsOneWidget);
  });
}

double _drawerHeight(WidgetTester tester) {
  return tester
      .getSize(find.byKey(const Key('favorites-section-drawer')))
      .height;
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required List<Equipment> favorites,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: FavoritesOverlay(
            child: ListView(
              children: const [
                SizedBox(height: 24),
                Text('Catalog item'),
                SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) =>
            const Scaffold(body: Text('Full favorites')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        favoritesProvider.overrideWith(
          (ref) => _StubFavoritesNotifier(favorites),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

Equipment _equipment(
  String id, {
  List<PriceEntry> prices = const [],
  UserModel? owner,
}) {
  return Equipment(
    id: id,
    name: 'Truck $id',
    model: 'TATRA',
    status: EquipmentStatus.available,
    isVisible: true,
    prices: prices,
    owner: owner,
  );
}

class _StubFavoritesNotifier extends FavoriteNotifier {
  _StubFavoritesNotifier(List<Equipment> items)
    : super(_FakeFavoriteService()) {
    state = FavoritesState(
      favorites: items,
      favoritesIds: items.map((item) => item.id).toSet(),
    );
  }
}

class _FakeFavoriteService implements FavoriteService {
  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<ApiResponse<List<Equipment>>> getFavorites() async {
    return ApiResponse.success(const []);
  }

  @override
  Future<ApiResponse<void>> toggleFavorite(String equipmentId) {
    throw UnimplementedError();
  }
}
