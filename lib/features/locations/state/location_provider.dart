import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'location_service.dart';
import 'location_notifier.dart';
import 'location_state.dart';

final locationApiProvider = Provider<LocationService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return LocationService(apiClient);
});

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    final api = ref.read(locationApiProvider);
    return LocationNotifier(api, ref);
  },
);
