import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/providers/equipment_dependencies.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';

class OwnerEquipmentDetailsNotifier
    extends FamilyAsyncNotifier<Equipment, String> {
  @override
  Future<Equipment> build(String id) async {
    final scope = ref.watch(authenticatedSessionScopeKeyProvider);
    if (scope == null) {
      throw const UnauthenticatedSessionScopeException();
    }
    final api = ref.read(equipmentServiceProvider);

    final result = await api.getOwnerEquipmentById(id);
    if (!isAuthenticatedSessionScopeCurrent(ref, scope)) {
      throw const UnauthenticatedSessionScopeException();
    }

    if (!result.success || result.data == null) {
      throw Exception(result.message);
    }

    return result.data!;
  }

  /// Prefer the owner-list row when it already reflects a newer moderation
  /// status, then refetch the full detail payload (admin comment, etc.).
  Future<void> refresh() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    final listItem = ref.read(ownerEquipmentProvider.notifier).findById(arg);
    final cached = state.valueOrNull;
    if (listItem != null &&
        (cached == null || cached.status != listItem.status)) {
      state = AsyncData(listItem);
    }

    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) rethrow;
    }
  }
}
