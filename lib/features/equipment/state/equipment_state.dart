import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class EquipmentState {
  final bool isLoading; // For initial load (Skeleton)
  final bool isFetchingMore; // For bottom spinner
  final String? error;
  final int currentPage;
  final bool hasReachedMax;

  final List<Equipment> ownerEquipment;
  final List<Equipment> renterEquipment;

  // Renter selected equipment for booking
  final Equipment? equipment;

  final Equipment? editEquipment;

  final Category? category;
  final LocationModel? location;

  EquipmentState({
    this.isLoading = false,
    this.isFetchingMore = false,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.error,
    this.ownerEquipment = const [],
    this.renterEquipment = const [],
    this.equipment,
    this.editEquipment,
    this.category,
    this.location,
  });

  EquipmentState copyWith({
    final bool? isLoading,
    bool? isFetchingMore,
    int? currentPage,
    bool? hasReachedMax,
    final String? error,
    List<Equipment>? ownerEquipment,
    List<Equipment>? renterEquipment,
    Category? category,
    Equipment? editEquipment,
  }) {
    return EquipmentState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      ownerEquipment: ownerEquipment ?? this.ownerEquipment,
      renterEquipment: renterEquipment ?? this.renterEquipment,
      category: category ?? this.category,
      editEquipment: editEquipment ?? this.editEquipment,
    );
  }
}
