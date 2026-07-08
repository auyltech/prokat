import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/features/equipment/state/equipment_state.dart';

class SearchEquipmentNotifier extends StateNotifier<EquipmentState> {
  final EquipmentService api;
  final Ref ref;

  SearchEquipmentNotifier(this.api, this.ref) : super(EquipmentState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void selectCategory(Category? category) {
    state = state.copyWith(category: category);
  }

  void clearCategory() {
    state = state.copyWith(category: null);
  }

  void clearQuery() {
    state = state.copyWith(query: "");
  }

  void clearFilters() {
    state = state.copyWith(query: "", category: null);
  }
}
