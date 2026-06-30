import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/state/equipment_state.dart';
import 'dart:io';

class EquipmentNotifier extends StateNotifier<EquipmentState> {
  final EquipmentService api;
  final Ref ref;

  EquipmentNotifier(this.api, this.ref) : super(EquipmentState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void selectCategory(Category category) {
    state = state.copyWith(category: category);
  }

  void selectEditEquipment(Equipment equipment) {
    state = state.copyWith(editEquipment: equipment);
  }

  void _startAction(String actionId) {
    state = state.copyWith(
      activeActions: {
        ...state.activeActions,
        Mutation(id: actionId, status: MutationStatus.submitting),
      },
    );
  }

  void _finishAction(String actionId, {AppError? error}) {
    final actions = {...state.activeActions};

    if (error == null) {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));
    } else {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));

      final action = Mutation(
        id: actionId,
        status: MutationStatus.error,
        error: error,
      );

      actions.add(action);
    }

    state = state.copyWith(activeActions: actions);
  }

  bool isActionActive(String actionId) {
    final foundAction = state.activeActions
        .where((item) => item.id == actionId)
        .firstOrNull;

    return foundAction == null
        ? false
        : foundAction.status == MutationStatus.submitting;
  }

  String? getActionError(String actionId) {
    final foundAction = state.activeActions
        .where((item) => item.id == actionId)
        .firstOrNull;

    return foundAction?.error?.message;
  }

  List<Equipment> _sortEquipment(List<Equipment> list) {
    final sorted = [...list];

    int statusPriority(EquipmentStatus status) {
      switch (status) {
        case EquipmentStatus.available:
          return 0;
        case EquipmentStatus.booked:
          return 1;
        case EquipmentStatus.maintenance:
          return 2;
        default:
          return 99;
      }
    }

    sorted.sort((a, b) {
      /// 1. Online first
      final aOnline = a.status == EquipmentStatus.available ? 0 : 1;
      final bOnline = b.status == EquipmentStatus.available ? 0 : 1;
      if (aOnline != bOnline) return aOnline.compareTo(bOnline);

      /// 2. Status priority
      final statusCompare = statusPriority(
        a.status,
      ).compareTo(statusPriority(b.status));
      if (statusCompare != 0) return statusCompare;

      /// 3. Last updated (descending)
      return (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0));
    });

    return sorted;
  }

  Future<void> getOwnerEquipment() async {
    try {
      final hasData = state.ownerEquipment.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getOwnerEquipment();

      state = state.copyWith(
        ownerEquipment: result.success
            ? _sortEquipment(result.data ?? [])
            : state.ownerEquipment,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "EQUIPMENT_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.ownerEquipment.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "EQUIPMENT_FETCH_FAILED",
        ),
      );
    }
  }

  Future<void> getOwnerEquipmentById(String id) async {
    try {
      final hasData = state.ownerEquipment.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getOwnerEquipmentById(id);

      state = state.copyWith(
        editEquipment: result.success ? result.data : state.editEquipment,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.message.toString(),
                code: "EQUIPMENT_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.ownerEquipment.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "EQUIPMENT_FETCH_FAILED",
        ),
      );
    }
  }

  // Used on main screen only => client fetches with pagination
  Future<void> getClientEquipment({
    String? categoryId,
    String? query,
    String? city,
    int? page,
    int? itemsPerPage,
  }) async {
    try {
      final hasData = state.clientEquipment.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getClientEquipment(
        categoryId: categoryId,
        query: query,
        page: state.currentPage,
        itemsPerPage: state.itemsPerPage,
        city: city,
      );

      print(result.success);

      state = state.copyWith(
        clientEquipment: result.success ? result.data : state.clientEquipment,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "EQUIPMENT_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientEquipment.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "EQUIPMENT_FETCH_FAILED",
        ),
      );
    }
  }

  // Handles fetching equipment by Id to create a booking
  Future<void> getClientEquipmentById(String id) async {
    try {
      final hasData = state.clientEquipment.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getClientEquipmentById(id);

      state = state.copyWith(
        clientBookingEquipment: result.success
            ? result.data
            : state.clientBookingEquipment,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.message.toString(),
                code: "EQUIPMENT_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientEquipment.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "EQUIPMENT_FETCH_FAILED",
        ),
      );
    }
  }

  Future<void> initFetch({
    String? categoryId,
    String? city,
    String? query,
  }) async {
    try {
      final hasData = state.clientEquipment.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getClientEquipment(
        page: 1,
        itemsPerPage: state.itemsPerPage,
        categoryId: categoryId,
        city: city,
        query: query,
      );

      if (!result.success || result.data == null) {
        state = state.copyWith(
          fetchStatus: hasData ? FetchStatus.success : FetchStatus.error,
          fetchError: AppError(
            type: ErrorType.unknown,
            message: result.error.toString(),
            code: "EQUIPMENT_FETCH_FAILED",
          ),
        );
        return;
      }

      state = state.copyWith(
        clientEquipment: result.success ? result.data : state.clientEquipment,
        hasReachedMax: (result.data?.length ?? 0) < state.itemsPerPage,
        currentPage: 1,
        paginationStatus: PaginationStatus.idle,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "EQUIPMENT_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientEquipment.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "EQUIPMENT_FETCH_FAILED",
        ),
      );
    }
  }

  Future<void> fetchNextPage({
    String? categoryId,
    String? query,
    String? city,
  }) async {
    try {
      // Prevent multiple simultaneous fetches or fetching if we hit the end
      if (state.hasReachedMax) return;

      if (state.paginationStatus == PaginationStatus.loadingMore) {
        return;
      }

      state = state.copyWith(paginationStatus: PaginationStatus.loadingMore);

      final nextPage = state.currentPage + 1;

      final result = await api.getClientEquipment(
        page: nextPage,
        itemsPerPage: state.itemsPerPage,
        categoryId: categoryId,
        city: city,
        query: query,
      );

      if (!result.success || result.data == null) {
        state = state.copyWith(paginationStatus: PaginationStatus.error);
        return;
      }

      final items = result.data!;

      state = state.copyWith(
        clientEquipment: [...state.clientEquipment, ...items],
        currentPage: nextPage,
        hasReachedMax: items.length < state.itemsPerPage,
        paginationStatus: PaginationStatus.idle,
      );
    } catch (error) {
      state = state.copyWith(paginationStatus: PaginationStatus.error);
    }
  }

  /// CREATE
  Future<bool> createEquipment(Map<String, dynamic> data) async {
    const actionId = "equipment:create";

    try {
      _startAction(actionId);

      final result = await api.createEquipment(data);

      _finishAction(
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
        getOwnerEquipment();
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
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
    final id = data["id"];

    if (id == null || id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$id:info";

    try {
      _startAction(actionId);

      final result = await api.updateEquipment(data);

      _finishAction(
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
        await Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
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
    final id = data["id"];

    if (id == null || id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$id:location";

    try {
      _startAction(actionId);

      final result = await api.updateEquipmentLocation(id, data);

      if (result.success) {
        await Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
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
    final id = equipmentId;

    if (id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$id:category";

    try {
      _startAction(actionId);

      final result = await api.updateEquipmentCategory(
        equipmentId: equipmentId,
        categoryId: categoryId,
      );

      _finishAction(
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
        await Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to update equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  // This function uses optimistic update with a revert to original
  Future<bool> updateVisibilityStatus(
    String equipmentId,
    bool isVisible,
    EquipmentStatus status,
  ) async {
    final id = equipmentId;

    if (id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$id:status";

    _startAction(actionId);

    final originalList = List<Equipment>.from(state.ownerEquipment);

    try {
      final updatedList = state.ownerEquipment.map((item) {
        if (item.id == equipmentId) {
          // Create a brand new instance instead of mutating the old one
          return item.copyWith(status: status, isVisible: isVisible);
        }
        return item;
      }).toList();

      final result = await api.updateVisibilityStatus(
        equipmentId: equipmentId,
        isVisible: isVisible,
        status: status,
      );

      _finishAction(
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
        state = state.copyWith(ownerEquipment: updatedList);

        Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);

        ref.read(billingProvider.notifier).getOwnerBalance();
      } else {
        state = state.copyWith(ownerEquipment: originalList);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to update equipment",
          code: "",
        ),
      );

      state = state.copyWith(ownerEquipment: originalList);

      return false;
    }
  }

  Future<bool> updateEquipmentSpecs(Map<String, dynamic> data) async {
    final id = data["id"];

    if (id == null || id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:update:$id:specs";

    try {
      _startAction(actionId);

      final result = await api.updateEquipmentSpecs(data);

      _finishAction(
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
        await Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
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
  Future<bool> deleteEquipment(String id) async {
    if (id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:delete:$id";

    try {
      _startAction(actionId);

      final result = await api.deleteEquipment(id);

      _finishAction(
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
        await getOwnerEquipment();
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to delete equipment",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> createPriceEntry(Map<String, dynamic> data) async {
    final id = data["id"];

    if (id == null || id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:price:create";

    try {
      _startAction(actionId);

      final result = await api.createPriceEntry(data);

      _finishAction(
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
        await Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to create price entry",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> updatePriceEntry(Map<String, dynamic> data) async {
    final equipmentId = data["equipmentId"];
    final id = data["id"];

    if (equipmentId == null ||
        equipmentId.toString().trim().isEmpty ||
        id == null ||
        id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:price:update:$id";

    try {
      _startAction(actionId);

      final result = await api.updatePriceEntry(data);

      _finishAction(
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
        await Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to update price entry",
          code: "",
        ),
      );

      return false;
    }
  }

  Future<bool> deletePriceEntry(Map<String, dynamic> data) async {
    final equipmentId = data["equipmentId"];
    final id = data["id"];

    if (equipmentId == null ||
        equipmentId.toString().trim().isEmpty ||
        id == null ||
        id.toString().trim().isEmpty) {
      return false;
    }

    final actionId = "equipment:price:delete:$id";

    try {
      _startAction(actionId);

      final result = await api.deletePriceEntry(data);

      _finishAction(
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
        await Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
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
      _startAction(actionId);

      final result = await api.uploadEquipmentImage(equipmentId, imageFile);

      _finishAction(
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
        Future.wait([getOwnerEquipmentById(id), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
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
      _startAction(actionId);

      final result = await api.deleteEquipmentImage(equipmentId, imageId);

      _finishAction(
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
        Future.wait([getOwnerEquipmentById(equipmentId), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
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
      _startAction(actionId);

      final result = await api.setPrimaryEquipmentImage(equipmentId, imageId);

      _finishAction(
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
        Future.wait([getOwnerEquipmentById(equipmentId), getOwnerEquipment()]);
      }

      return result.success;
    } catch (error) {
      _finishAction(
        actionId,
        error: AppError(
          type: ErrorType.unknown,
          message: "Failed to update image",
          code: "",
        ),
      );

      return false;
    }
  }
}
