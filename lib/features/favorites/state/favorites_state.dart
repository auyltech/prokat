import 'package:prokat/features/equipment/models/equipment_model.dart';

class FavoritesState {
  static const _notProvided = Object();

  final bool isLoading;
  final String? error;

  final Set<String>? favoritesIds;
  final List<Equipment>? favorites;

  FavoritesState({
    this.isLoading = false,
    this.error,
    this.favoritesIds,
    this.favorites,
  });

  FavoritesState copyWith({
    bool? isLoading,
    Object? error = _notProvided,
    Set<String>? favoritesIds,
    List<Equipment>? favorites,
  }) {
    assert(
      identical(error, _notProvided) || error is String?,
      'error must be a String or null',
    );

    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _notProvided) ? this.error : error as String?,
      favoritesIds: favoritesIds ?? this.favoritesIds,
      favorites: favorites ?? this.favorites,
    );
  }
}
