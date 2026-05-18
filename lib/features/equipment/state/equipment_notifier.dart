import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/state/equipment_state.dart';
import 'dart:io';

class EquipmentNotifier extends StateNotifier<EquipmentState> {
  final EquipmentService api;

  EquipmentNotifier(this.api) : super(EquipmentState());

  static const int _limit = 10;

  void selectCategory(Category category) {
    state = state.copyWith(category: category);
  }

  void selectEditEquipment(Equipment equipment) {
    state = state.copyWith(editEquipment: equipment);
  }

  List<Equipment> _sortEquipment(List<Equipment> list) {
    final sorted = [...list];

    int statusPriority(String status) {
      switch (status) {
        case 'available':
          return 0;
        case 'booked':
          return 1;
        case 'maintenance':
          return 2;
        default:
          return 99;
      }
    }

    sorted.sort((a, b) {
      /// 1. Online first
      final aOnline = a.status == 'available' ? 0 : 1;
      final bOnline = b.status == 'available' ? 0 : 1;
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      final equipment = await api.getOwnerEquipment();

      state = state.copyWith(
        ownerEquipment: _sortEquipment(equipment),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getOwnerEquipmentById(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await api.getOwnerEquipmentById(id);

      if (result.success) {
        state = state.copyWith(editEquipment: result.data, isLoading: false);
      } else {
        state = state.copyWith(
          error: result.message,
          editEquipment: result.data,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getRenterEquipment({
    String? categoryId,
    String? query,
    String? city,
    int? page,
    int? limit,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await api.getRenterEquipment(
        categoryId: categoryId,
        query: query,
        page: page,
        limit: limit,
        city: city,
      );

      state = state.copyWith(
        renterEquipment: result.data,
        isLoading: false,
        error: result.error,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> initFetch({
    String? categoryId,
    String? city,
    String? query,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      renterEquipment: [],
      currentPage: 1,
    );

    try {
      final items = await api.getClientEquipment(
        page: 1,
        limit: _limit,
        categoryId: categoryId,
        city: city,
        query: query,
      );

      state = state.copyWith(
        renterEquipment: items,
        isLoading: false,
        hasReachedMax: items.length < _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchNextPage({
    String? categoryId,
    String? query,
    String? city,
  }) async {
    // Prevent multiple simultaneous fetches or fetching if we hit the end
    if (state.isFetchingMore || state.hasReachedMax) return;

    state = state.copyWith(isFetchingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final newItems = await api.getClientEquipment(
        page: nextPage,
        limit: _limit,
        categoryId: categoryId,
        city: city,
        query: query,
      );

      state = state.copyWith(
        renterEquipment: [...state.renterEquipment, ...newItems],
        currentPage: nextPage,
        isFetchingMore: false,
        hasReachedMax: newItems.length < _limit,
      );
    } catch (e) {
      state = state.copyWith(isFetchingMore: false);
      // Optional: Show a snackbar error for fetch-more failures
    }
  }

  Equipment? getById(String id) {
    try {
      return state.ownerEquipment.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setImageActionInProgress(String equipmentId, bool inProgress) {
    final set = {...state.imageActionInProgressEquipmentIds};

    if (inProgress) {
      set.add(equipmentId);
    } else {
      set.remove(equipmentId);
    }

    state = state.copyWith(imageActionInProgressEquipmentIds: set);
  }

  void _setImageActionError(String equipmentId, String? message) {
    final map = {...state.imageActionErrorByEquipmentId};
    map[equipmentId] = message;
    state = state.copyWith(imageActionErrorByEquipmentId: map);
  }

  String _normalizeError(Object error) {
    final text = error.toString();
    const prefix = 'Exception: ';
    if (text.startsWith(prefix)) return text.substring(prefix.length);
    return text;
  }

  void _replaceOwnerEquipment(Equipment updated) {
    final list = state.ownerEquipment
        .map((e) => e.id == updated.id ? updated : e)
        .toList();

    state = state.copyWith(ownerEquipment: _sortEquipment(list));
  }

  Future<bool> uploadEquipmentImage({
    required String equipmentId,
    required File imageFile,
  }) async {
    _setImageActionError(equipmentId, null);
    _setImageActionInProgress(equipmentId, true);

    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.uploadEquipmentImage(equipmentId, imageFile);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }

      // _setImageActionError(
      //   equipmentId,
      //   'Upload succeeded but no data returned',
      // );
      // return false;
    } catch (e) {
      _setImageActionError(equipmentId, _normalizeError(e));
      return false;
    } finally {
      _setImageActionInProgress(equipmentId, false);
    }
  }

  Future<bool> deleteEquipmentImage({
    required String equipmentId,
    required String imageId,
  }) async {
    _setImageActionError(equipmentId, null);
    _setImageActionInProgress(equipmentId, true);

    try {
      final updated = await api.deleteEquipmentImage(equipmentId, imageId);

      if (updated != null) {
        _replaceOwnerEquipment(updated);
        return true;
      }

      _setImageActionError(
        equipmentId,
        'Delete succeeded but no data returned',
      );
      return false;
    } catch (e) {
      _setImageActionError(equipmentId, _normalizeError(e));
      return false;
    } finally {
      _setImageActionInProgress(equipmentId, false);
    }
  }

  Future<bool> setPrimaryEquipmentImage({
    required String equipmentId,
    required String imageId,
  }) async {
    _setImageActionError(equipmentId, null);
    _setImageActionInProgress(equipmentId, true);

    try {
      final updated = await api.setPrimaryEquipmentImage(equipmentId, imageId);

      if (updated != null) {
        _replaceOwnerEquipment(updated);
        return true;
      }

      _setImageActionError(
        equipmentId,
        'Cover update succeeded but no data returned',
      );
      return false;
    } catch (e) {
      _setImageActionError(equipmentId, _normalizeError(e));
      return false;
    } finally {
      _setImageActionInProgress(equipmentId, false);
    }
  }

  /// CREATE
  Future<bool> createEquipment(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.createEquipment(data);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      return false;
    }
  }

  /// UPDATE
  Future<bool> updateEquipment(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.updateEquipment(data);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }

  Future<bool> updateEquipmentLocation(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.updateEquipmentLocation(id, data);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }

  Future<bool> updateEquipmentCategory({
    required String equipmentId,
    required String categoryId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.updateEquipmentCategory(
        equipmentId: equipmentId,
        categoryId: categoryId,
      );

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }

  Future<bool> updateVisibilityStatus(
    String equipmentId,
    bool isVisible,
    String status,
  ) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      final result = await api.updateVisibilityStatus(
        equipmentId: equipmentId,
        isVisible: isVisible,
        status: status,
      );

      if (result.success) {
        state = state.copyWith(isSubmitting: false);

        await getOwnerEquipmentById(equipmentId);
        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isSubmitting: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());

      return false;
    }
  }

  Future<bool> updateEquipmentSpecs(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.updateEquipmentSpecs(data);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();
        await getOwnerEquipmentById(data["id"] ?? "");

        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }

  /// DELETE
  Future<bool> deleteEquipment(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.deleteEquipment(id);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }

  Future<bool> createPriceEntry(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.createPriceEntry(data);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }

  Future<bool> updatePriceEntry(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.updatePriceEntry(data);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }

  Future<bool> deletePriceEntry(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.deletePriceEntry(data);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        await getOwnerEquipment();

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());

      return false;
    }
  }
}
