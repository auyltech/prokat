import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import '../models/request_model.dart';

class Value<T> {
  final T value;
  const Value(this.value);
}

class RequestState {
  final FetchStatus fetchStatus;
  final PaginationStatus paginationStatus;

  final DateTime? lastFetchedAt;
  final AppError? fetchError;

  final Set<Mutation> activeActions;

  /// All requests (list screen)
  final List<RequestModel> clientRequests;
  final List<RequestModel> ownerRequests;

  /// Current opened request (details/edit)
  final RequestModel? draftRequest;

  /// 🔥 Draft (before creating request)
  final String? capacity;
  final int? offeredRate;
  final String? comment;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final LocationModel? selectedLocation;
  final String? selectedLocationId;
  final Category? selectedCategory;
  final String? categoryId;

  RequestState({
    this.fetchStatus = FetchStatus.initial,
    this.paginationStatus = PaginationStatus.idle,
    this.lastFetchedAt,
    this.fetchError,
    this.activeActions = const {},

    this.clientRequests = const [],
    this.ownerRequests = const [],
    this.draftRequest,
    this.capacity,
    this.offeredRate,
    this.comment,
    this.selectedDate,
    this.selectedTime,
    this.selectedLocation,
    this.selectedLocationId,
    this.selectedCategory,
    this.categoryId,
  });

  List<RequestModel> get activeOwnerRequests {
    return ownerRequests
        .where(
          (r) => [
            RequestStatus.created,
            RequestStatus.viewed,
            RequestStatus.responded,
          ].contains(r.status),
        )
        .toList();
  }

  RequestState copyWith({
    FetchStatus? fetchStatus,
    PaginationStatus? paginationStatus,
    DateTime? lastFetchedAt,
    AppError? fetchError,
    Set<Mutation>? activeActions,

    List<RequestModel>? clientRequests,
    List<RequestModel>? ownerRequests,
    RequestModel? draftRequest,
    String? capacity,
    int? offeredRate,
    String? comment,
    DateTime? selectedDate,
    DateTime? selectedTime,
    LocationModel? selectedLocation,
    String? selectedLocationId,
    Category? selectedCategory,
    String? categoryId,
  }) {
    return RequestState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchError: fetchError,
      activeActions: activeActions ?? this.activeActions,

      clientRequests: clientRequests ?? this.clientRequests,
      ownerRequests: ownerRequests ?? this.ownerRequests,
      draftRequest: draftRequest ?? this.draftRequest,
      capacity: capacity ?? this.capacity,
      offeredRate: offeredRate ?? this.offeredRate,
      comment: comment ?? this.comment,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
