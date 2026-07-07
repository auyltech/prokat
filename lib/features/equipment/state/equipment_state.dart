import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/locations/models/location_model.dart';

class EquipmentState {
  final FetchStatus? fetchStatus; // For initial load (Skeleton)
  final PaginationStatus paginationStatus; // For bottom spinner

  final DateTime? lastFetchedAt;
  final AppError? fetchError;

  final Set<Mutation> activeActions;

  final String? query;
  final String? searchCity;
  final String? searchCategoryId;

  final int currentPage;
  final int itemsPerPage;
  final bool hasReachedMax;

  final List<Equipment> ownerEquipment;
  final List<Equipment> clientEquipment;

  // Renter selected equipment for booking
  final Equipment? clientBookingEquipment;
  final Equipment? editEquipment;

  final Category? category;
  final LocationModel? location;

  int get onlineEquipmentCount {
    return ownerEquipment.where((item) => item.isVisible).length;
  }

  bool get isLoading =>
      fetchStatus == null ? false : fetchStatus == FetchStatus.loading;

  bool get isRefreshing => fetchStatus == FetchStatus.refreshing;

  bool get hasData => ownerEquipment.isNotEmpty || clientEquipment.isNotEmpty;

  EquipmentState({
    this.fetchStatus = FetchStatus.initial,
    this.paginationStatus = PaginationStatus.idle,
    this.lastFetchedAt,
    this.fetchError,
    this.activeActions = const {},

    this.query = "",
    this.searchCity,
    this.searchCategoryId,

    this.currentPage = 1,
    this.itemsPerPage = 5,
    this.hasReachedMax = false,

    this.ownerEquipment = const [],
    this.clientEquipment = const [],
    this.clientBookingEquipment,
    this.editEquipment,
    this.category,
    this.location,
  });

  bool get isSubmitting {
    return activeActions
        .where((item) => item.status == MutationStatus.submitting)
        .isNotEmpty;
  }

  bool isActionActive(String actionId) {
    return activeActions
            .where(
              (item) =>
                  item.id == actionId &&
                  item.status == MutationStatus.submitting,
            )
            .firstOrNull !=
        null;
  }

  EquipmentState copyWith({
    FetchStatus? fetchStatus,
    PaginationStatus? paginationStatus,
    DateTime? lastFetchedAt,
    AppError? fetchError,
    Set<Mutation>? activeActions,

    String? query,
    String? searchCity,
    String? searchCategoryId,

    int? currentPage,
    int? itemsPerPage,
    bool? hasReachedMax,

    List<Equipment>? ownerEquipment,
    List<Equipment>? clientEquipment,

    Category? category,
    Equipment? editEquipment,
    Equipment? clientBookingEquipment,
  }) {
    return EquipmentState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchError: fetchError,
      activeActions: activeActions ?? this.activeActions,

      query: query ?? this.query,
      searchCity: searchCity ?? this.searchCity,
      searchCategoryId: searchCategoryId ?? this.searchCategoryId,

      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,

      ownerEquipment: ownerEquipment ?? this.ownerEquipment,
      clientEquipment: clientEquipment ?? this.clientEquipment,

      category: category ?? this.category,

      editEquipment: editEquipment ?? this.editEquipment,
      clientBookingEquipment:
          clientBookingEquipment ?? this.clientBookingEquipment,
    );
  }
}
