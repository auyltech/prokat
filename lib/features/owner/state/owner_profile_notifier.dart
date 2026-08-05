import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';

class OwnerProfileNotifier extends AsyncNotifier<OwnerProfileModel?> {
  OwnerRegistrationService get api =>
      ref.read(ownerRegistrationServiceProvider);

  static const staleAfter = Duration(minutes: 5);
  DateTime? _lastFetchedAt;
  Future<void>? _refreshing;

  @override
  Future<OwnerProfileModel?> build() async {
    return _fetch();
  }

  Future<OwnerProfileModel?> _fetch() async {
    final profile = await api.getOwnerProfile();
    _lastFetchedAt = DateTime.now();
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
    final hadData = state is AsyncData<OwnerProfileModel?>;
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
