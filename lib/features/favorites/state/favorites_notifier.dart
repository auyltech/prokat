import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/favorites/state/favorites_service.dart';
import 'package:prokat/features/favorites/state/favorites_state.dart';

class FavoriteNotifier extends StateNotifier<FavoritesState> {
  final FavoriteService service;

  FavoriteNotifier(this.service) : super(FavoritesState());

  Future<bool> getFavorites() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.getFavorites();

      state = state.copyWith(
        isLoading: false,
        favoritesIds: result.data?.map((item) => item.id).toSet(),
        favorites: result.data,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  bool isFavorite(String id) {
    return state.favoritesIds?.contains(id) ?? false;
  }

  Future<bool> toggleFavorite(String equipmentId) async {
    try {
      state = state.copyWith(isLoading: true);

      final current = state.favoritesIds;

      // Optimistic update
      final isFav = current?.contains(equipmentId) ?? false;
      final updated = Set<String>.from(current ?? []);

      if (isFav) {
        updated.remove(equipmentId);
      } else {
        updated.add(equipmentId);
      }

      state = state.copyWith(favoritesIds: updated);

      final result = await service.toggleFavorite(equipmentId);

      state = state.copyWith(isLoading: false);

      await getFavorites();

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
