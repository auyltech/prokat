import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/state/client_profile_service.dart';

class ClientProfileNotifier extends AsyncNotifier<UserProfileModel?> {
  static const staleAfter = Duration(minutes: 5);

  late final ClientProfileService service;
  DateTime? _lastFetchedAt;
  Future<void>? _refreshing;

  @override
  Future<UserProfileModel?> build() async {
    service = ref.read(clientProfileServiceProvider);
    return _fetch();
  }

  Future<UserProfileModel?> _fetch() async {
    final profile = await service.getUserProfile();
    _lastFetchedAt = DateTime.now();
    if (profile != null) {
      ref.read(locationProvider.notifier).selectCity(profile.city ?? '');
      ref
          .read(locationProvider.notifier)
          .selectAddressById(profile.selectedAddressId);
    }
    return profile;
  }

  Future<void> refresh() {
    final active = _refreshing;
    if (active != null) return active;
    final operation = _refresh();
    _refreshing = operation;
    return operation.whenComplete(() => _refreshing = null);
  }

  Future<void> _refresh() async {
    final hadData = state is AsyncData<UserProfileModel?>;
    final previous = state.value;
    if (!hadData && state.isLoading) {
      try {
        await future;
        return;
      } catch (_) {}
    }

    if (!hadData) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
      return;
    }

    try {
      state = AsyncData(await _fetch());
    } catch (_) {
      state = AsyncData(previous);
    }
  }

  Future<void> refreshIfStale() async {
    if (state.isLoading) {
      try {
        await future;
      } catch (_) {}
    }
    final fetchedAt = _lastFetchedAt;
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt) > staleAfter) {
      await refresh();
    }
  }

  void invalidate() => _lastFetchedAt = null;
}
