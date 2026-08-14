import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/guest_equipment_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';

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

  Future<void> refresh() async {
    final scope = readAuthenticatedSessionScope(ref);
    if (scope == null) return;

    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      if (isAuthenticatedSessionScopeCurrent(ref, scope)) rethrow;
    }
  }
}
