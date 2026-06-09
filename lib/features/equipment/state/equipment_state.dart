import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class EquipmentState {
  final bool isLoading; // For initial load (Skeleton)
  final bool isFetchingMore; // For bottom spinner

  final bool isSubmitting;

  final String? actionId;
  final String? error;

  final String? query;
  final int currentPage;
  final int itemsPerPage;
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

    this.isSubmitting = false,
    this.actionId,

    this.error,

    this.query = "",
    this.currentPage = 1,
    this.itemsPerPage = 5,
    this.hasReachedMax = false,
    this.imageActionInProgressEquipmentIds = const {},
    this.imageActionErrorByEquipmentId = const {},
    this.ownerEquipment = const [],
    this.renterEquipment = const [],
    this.equipment,
    this.editEquipment,
    this.category,
    this.location,
  });

  EquipmentState copyWith({
    bool? isLoading,
    bool? isFetchingMore,
    bool? isSubmitting,
    String? actionId,
    String? query,
    int? currentPage,
    int? itemsPerPage,
    bool? hasReachedMax,
    String? error,
    Set<String>? imageActionInProgressEquipmentIds,
    Map<String, String?>? imageActionErrorByEquipmentId,
    List<Equipment>? ownerEquipment,
    List<Equipment>? renterEquipment,
    Category? category,
    Equipment? editEquipment,
  }) {
    return EquipmentState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionId: actionId ?? this.actionId,
      error: error, // this.error is set if the error passed is null
      query: query ?? this.query,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
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
