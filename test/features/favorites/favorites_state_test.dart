import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/favorites/state/favorites_notifier.dart';
import 'package:prokat/features/favorites/state/favorites_service.dart';
import 'package:prokat/features/favorites/state/favorites_state.dart';

void main() {
  group('FavoritesState.copyWith', () {
    test('retains error when it is omitted', () {
      final state = FavoritesState(error: 'network');

      final updated = state.copyWith(isLoading: false);

      expect(updated.error, 'network');
      expect(updated.isLoading, isFalse);
    });

    test('clears error when null is passed explicitly', () {
      final state = FavoritesState(error: 'network', isLoading: true);

      final updated = state.copyWith(isLoading: false, error: null);

      expect(updated.error, isNull);
      expect(updated.isLoading, isFalse);
    });
  });

  test('successful getFavorites clears a previous error', () async {
    final notifier = FavoriteNotifier(_FakeFavoriteService());
    addTearDown(notifier.dispose);
    notifier.state = FavoritesState(error: 'network', isLoading: true);

    final succeeded = await notifier.getFavorites();

    expect(succeeded, isTrue);
    expect(notifier.state.error, isNull);
    expect(notifier.state.isLoading, isFalse);
  });
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
