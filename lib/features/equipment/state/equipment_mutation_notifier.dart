import 'dart:async';
import 'dart:io';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/core/mutation/mutation_notifier.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/equipment_spec_value_input.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/state/equipment_mutation_state.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EquipmentMutationNotifier
    extends MutationNotifier<EquipmentMutationState> {
  final EquipmentService api;
  final Ref ref;

  EquipmentMutationNotifier({required this.api, required this.ref})
    : super(const EquipmentMutationState());

  @override
  Set<Mutation> get activeActions => state.activeActions;

  @override
  EquipmentMutationState copyState({Set<Mutation>? activeActions}) {
    return state.copyWith(activeActions: activeActions);
  }

  void selectEditEquipment(String equipmentId) {
    state = state.copyWith(editingEquipmentId: equipmentId);
  }

  void clearEditEquipment() {
    state = state.copyWith(editingEquipmentId: null);
  }

  void selectCategory(Category category) {
    state = state.copyWith(category: category);
  }

  void clearCategory() {
    state = state.copyWith(category: null);
  }

  Future<void> _refreshEquipmentCaches(String equipmentId) async {
    ref.invalidate(ownerEquipmentDetailsProvider(equipmentId));
    await ref.read(ownerEquipmentProvider.notifier).refresh();
  }

  /// CREATE
  Future<bool> createEquipment(Map<String, dynamic> data) async {
    const actionId = "equipment:create";

    try {
      startAction(actionId);

      final result = await api.createEquipment(data);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await ref.read(ownerEquipmentProvider.notifier).refresh();
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to create equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  /// UPDATE
  Future<bool> updateEquipment(Map<String, dynamic> data) async {
    final equipmentId = data["id"];

    if (equipmentId == null || equipmentId.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$equipmentId:info";

    try {
      startAction(actionId);

      final result = await api.updateEquipment(data);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to update equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> updateEquipmentLocation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final equipmentId = data["id"];

    if (equipmentId == null || equipmentId.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$equipmentId:location";

    try {
      startAction(actionId);

      final result = await api.updateEquipmentLocation(id, data);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to update equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> updateEquipmentCategory({
    required String equipmentId,
    required String categoryId,
  }) async {
    if (equipmentId.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$equipmentId:category";

    try {
      startAction(actionId);

      final result = await api.updateEquipmentCategory(
        equipmentId: equipmentId,
        categoryId: categoryId,
      );

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to update equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  // This function uses optimistic update with a revert to original
  Future<bool> updateEquipmentStatus(
    String equipmentId,
    EquipmentStatus status,
  ) async {
    final actionId = "equipment:update:$equipmentId:status";

    startAction(actionId);

    final ownerNotifier = ref.read(ownerEquipmentProvider.notifier);
    final original = ownerNotifier.findById(equipmentId);

    if (original != null) {
      await ownerNotifier.replaceItem(
        equipmentId,
        (item) => item.copyWith(status: status),
      );
    }

    try {
      final result = await api.updateEquipmentStatus(
        equipmentId: equipmentId,
        status: status,
      );

      if (result.success) {
        finishAction(actionId);

        await _refreshEquipmentCaches(equipmentId);
        unawaited(ref.read(billingProvider.notifier).getOwnerBalance());

        return true;
      }

      if (original != null) {
        await ownerNotifier.replaceItem(equipmentId, (_) => original);
      }

      finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          code: "",
          message: result.message,
        ),
      );

      return false;
    } catch (_) {
      if (original != null) {
        await ownerNotifier.replaceItem(equipmentId, (_) => original);
      }

      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          code: "",
          message: "Failed to update equipment.",
        ),
      );

      return false;
    }
  }

  Future<bool> toggleEquipmentOnline(String equipmentId, bool isVisible) async {
    final actionId = "equipment:update:$equipmentId:visibility";

    startAction(actionId);

    final ownerNotifier = ref.read(ownerEquipmentProvider.notifier);
    final original = ownerNotifier.findById(equipmentId);

    if (original == null) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          code: "",
          message: "Equipment not found.",
        ),
      );
      return false;
    }

    await ownerNotifier.replaceItem(
      equipmentId,
      (item) => item.copyWith(isVisible: isVisible),
    );

    try {
      final result = await api.toggleEquipmentOnline(
        equipmentId: equipmentId,
        isVisible: isVisible,
      );

      if (result.success) {
        finishAction(actionId);

        unawaited(ref.read(billingProvider.notifier).getOwnerBalance());
        await _refreshEquipmentCaches(equipmentId);

        return true;
      }

      await ownerNotifier.replaceItem(equipmentId, (_) => original);

      finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          code: "",
          message: result.message,
        ),
      );

      return false;
    } catch (_) {
      await ownerNotifier.replaceItem(equipmentId, (_) => original);

      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          code: "",
          message: "Failed to update equipment.",
        ),
      );

      return false;
    }
  }

  Future<bool> updateEquipmentSpecs({
    required String equipmentId,
    required List<EquipmentSpecValueInput> specs,
  }) async {
    if (equipmentId.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$equipmentId:specs";

    try {
      startAction(actionId);

      final result = await api.updateEquipmentSpecValues(
        equipmentId: equipmentId,
        specs: specs,
      );

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to update equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  /// DELETE Equipment
  /// Allowed until equipment has a booking or offer (handled by backed)
  Future<bool> deleteEquipment(String equipmentId) async {
    if (equipmentId.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:delete:$equipmentId";

    try {
      startAction(actionId);

      final result = await api.deleteEquipment(equipmentId);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to delete equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<MutationResponse> createPriceEntry(
    int price,
    PriceRateOption priceRate,
    String equipmentId,
  ) async {
    if (equipmentId.toString().trim().isEmpty) {
      return MutationResponse(
        success: false,
        message: "Please provide required data",
      );
    }

    const actionId = "equipment:price:create";

    try {
      startAction(actionId);

      final result = await api.createPriceEntry(price, priceRate, equipmentId);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return MutationResponse(
        success: result.success,
        message: result.success
            ? "Price entry added"
            : "Failed to create price entry",
      );
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to create price entry",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to create price entry",
      );
    }
  }

  Future<MutationResponse> updatePriceEntry(
    PriceEntry entry,
    String equipmentId,
  ) async {
    final id = entry.id;

    if (equipmentId.toString().trim().isEmpty || id.toString().trim().isEmpty) {
      return MutationResponse(
        success: false,
        message: "Please provide required data",
      );
    }

    final actionId = "equipment:price:update:$id";

    try {
      startAction(actionId);

      final result = await api.updatePriceEntry(entry, equipmentId);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return MutationResponse(
        success: result.success,
        message: result.success
            ? "Price entry saved"
            : "Failed to save price entry",
      );
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to update price entry",
          code: "",
        ),
      );

      return MutationResponse(
        success: false,
        message: "Failed to update price entry",
      );
    }
  }

  Future<bool> deletePriceEntry(PriceEntry entry, String equipmentId) async {
    final id = entry.id;

    if (id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:price:delete:$id";

    try {
      startAction(actionId);

      final result = await api.deletePriceEntry(entry, equipmentId);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to delete price entry",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> uploadEquipmentImage({
    required String equipmentId,
    required File imageFile,
  }) async {
    final id = equipmentId;

    if (id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:image:create:$id";

    try {
      startAction(actionId);

      final result = await api.uploadEquipmentImage(equipmentId, imageFile);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to upload image",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> deleteEquipmentImage({
    required String equipmentId,
    required String imageId,
  }) async {
    final id = imageId;

    if (id.toString().trim().isEmpty || equipmentId.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:image:delete:$id";

    try {
      startAction(actionId);

      final result = await api.deleteEquipmentImage(equipmentId, imageId);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to delete image",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> setPrimaryEquipmentImage({
    required String equipmentId,
    required String imageId,
  }) async {
    final id = imageId;

    if (id.toString().trim().isEmpty || equipmentId.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:image:update:$id";

    try {
      startAction(actionId);

      final result = await api.setPrimaryEquipmentImage(equipmentId, imageId);

      finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        await _refreshEquipmentCaches(equipmentId);
      }

      return result.success;
    } catch (error) {
      finishAction(
        actionId,
        error: const AppError(
          type: ErrorType.unknown,
          message: "Failed to update image",
          code: "",
        ),
      );

      return false;
    }
  }
}
