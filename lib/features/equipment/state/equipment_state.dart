import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class EquipmentState {
  static const _notProvided = Object();

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
    Object? searchCity = _notProvided,
    Object? searchCategoryId = _notProvided,
    Object? category = _notProvided,
    Object? location = _notProvided,
  }) {
    assert(
      identical(searchCity, _notProvided) || searchCity is String?,
      'searchCity must be a String or null',
    );
    assert(
      identical(searchCategoryId, _notProvided) || searchCategoryId is String?,
      'searchCategoryId must be a String or null',
    );
    assert(
      identical(category, _notProvided) || category is Category?,
      'category must be a Category or null',
    );
    assert(
      identical(location, _notProvided) || location is LocationModel?,
      'location must be a LocationModel or null',
    );

    return EquipmentState(
      query: query ?? this.query,
      searchCity: identical(searchCity, _notProvided)
          ? this.searchCity
          : searchCity as String?,
      searchCategoryId: identical(searchCategoryId, _notProvided)
          ? this.searchCategoryId
          : searchCategoryId as String?,
      category: identical(category, _notProvided)
          ? this.category
          : category as Category?,
      location: identical(location, _notProvided)
          ? this.location
          : location as LocationModel?,
    );
  }
}
