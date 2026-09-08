import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/favorites/screens/favorites_screen.dart';
import 'package:prokat/features/favorites/state/favorites_notifier.dart';
import 'package:prokat/features/favorites/state/favorites_provider.dart';
import 'package:prokat/features/favorites/state/favorites_service.dart';
import 'package:prokat/features/favorites/state/favorites_state.dart';
import 'package:prokat/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('favorite cards show owner, rating, orders and price', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final equipment = Equipment(
      id: 'eq-1',
      name: 'вакуум',
      model: '123',
      status: EquipmentStatus.available,
      isVisible: true,
      owner: const UserModel(
        firstName: 'Ерлан',
        lastName: 'Садыков',
        rating: 5,
        orderCount: 21,
      ),
      prices: [
        PriceEntry(
          id: 'price-1',
          price: 1500,
          priceRate: parseRateOption('PER_CUBIC_METER'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesProvider.overrideWith(
            (ref) => _StubFavoritesNotifier([equipment]),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FavoritesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('вакуум'), findsOneWidget);
    expect(find.text('Ерлан Садыков'), findsOneWidget);
    expect(find.textContaining('21 orders'), findsOneWidget);
    expect(find.textContaining('1,500'), findsOneWidget);
    expect(find.text('No price'), findsNothing);
  });
}

class _StubFavoritesNotifier extends FavoriteNotifier {
  _StubFavoritesNotifier(List<Equipment> items)
    : super(_FakeFavoriteService(items)) {
    state = FavoritesState(
      favorites: items,
      favoritesIds: items.map((item) => item.id).toSet(),
    );
  }
}

class _FakeFavoriteService implements FavoriteService {
  _FakeFavoriteService(this.items);

  final List<Equipment> items;

  @override
  ApiClient get apiClient => throw UnimplementedError();

  @override
  Future<ApiResponse<List<Equipment>>> getFavorites() async {
    return ApiResponse.success(items);
  }

  @override
  Future<ApiResponse<void>> toggleFavorite(String equipmentId) {
    throw UnimplementedError();
  }
}
