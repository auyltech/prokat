import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class EquipmentState {
  final bool isLoading; // For initial load (Skeleton)

  final bool isSubmitting; // For initial load (Skeleton)

  final bool isFetchingMore; // For bottom spinner
  final String? error;
  final int currentPage;
  final bool hasReachedMax;

  final Set<String> imageActionInProgressEquipmentIds;
  final Map<String, String?> imageActionErrorByEquipmentId;

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
    this.imageActionInProgressEquipmentIds = const {},
    this.imageActionErrorByEquipmentId = const {},
    this.ownerEquipment = const [],
    this.renterEquipment = const [],
    this.equipment,
    this.editEquipment,
    this.category,
    this.location,
    this.isSubmitting = false,
  });

  EquipmentState copyWith({
    final bool? isLoading,
    final bool? isSubmitting,
    bool? isFetchingMore,
    int? currentPage,
    bool? hasReachedMax,
    final String? error,
    Set<String>? imageActionInProgressEquipmentIds,
    Map<String, String?>? imageActionErrorByEquipmentId,
    List<Equipment>? ownerEquipment,
    List<Equipment>? renterEquipment,
    Category? category,
    Equipment? editEquipment,
  }) {
    return EquipmentState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      error: error, // this.error is set if the error passed is null
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      imageActionInProgressEquipmentIds:
          imageActionInProgressEquipmentIds ??
          this.imageActionInProgressEquipmentIds,
      imageActionErrorByEquipmentId:
          imageActionErrorByEquipmentId ?? this.imageActionErrorByEquipmentId,
      ownerEquipment: ownerEquipment ?? this.ownerEquipment,
      renterEquipment: renterEquipment ?? this.renterEquipment,
      category: category ?? this.category,
      editEquipment: editEquipment ?? this.editEquipment,
    );
  }
}
