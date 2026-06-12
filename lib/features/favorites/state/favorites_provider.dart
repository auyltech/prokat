import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/api_provider.dart';
import 'package:prokat/features/favorites/state/favorites_notifier.dart';
import 'package:prokat/features/favorites/state/favorites_service.dart';
import 'package:prokat/features/favorites/state/favorites_state.dart';

final favoritesServiceProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);

  return FavoriteService(dio);
});

final favoritesProvider =
    StateNotifierProvider<FavoriteNotifier, FavoritesState>((ref) {
      final service = ref.read(favoritesServiceProvider);
      return FavoriteNotifier(service);
    });
