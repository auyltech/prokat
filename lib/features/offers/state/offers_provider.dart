import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/offers/state/offers_service.dart';
import 'package:prokat/features/offers/state/offers_notifier.dart';
import 'package:prokat/features/offers/state/offers_state.dart';

final offersServiceProvider = Provider<OffersService>((ref) {
  final dio = ref.watch(apiClientProvider);

  return OffersService(dio);
});

final offersProvider = StateNotifierProvider<OffersNotifier, OffersState>((
  ref,
) {
  final service = ref.read(offersServiceProvider);
  return OffersNotifier(service);
});
