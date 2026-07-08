import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class EquipmentState {
  final String? query;
  final String? searchCity;
  final String? searchCategoryId;

  final Category? category;
  final LocationModel? location;

  EquipmentState({
    this.query = "",
    this.searchCity,
    this.searchCategoryId,

    this.category,
    this.location,
  });

  EquipmentState copyWith({
    String? query,
    String? searchCity,
    String? searchCategoryId,

    Category? category,
    LocationModel? location,
  }) {
    return EquipmentState(
      query: query ?? this.query,
      searchCity: searchCity ?? this.searchCity,
      searchCategoryId: searchCategoryId ?? this.searchCategoryId,

      category: category ?? this.category,
      location: location ?? this.location,
    );
  }
}
