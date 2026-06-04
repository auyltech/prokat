import 'package:prokat/features/categories/models/category.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/requests/models/request_status.dart';
import '../models/request_model.dart';

class RequestState {
  final bool isLoading;
  final String? error;

  /// All requests (list screen)
  final List<RequestModel> requests;
  final List<RequestModel> ownerRequests;

  /// Current opened request (details/edit)
  final RequestModel? currentRequest;

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
    this.isLoading = false,
    this.error,
    this.requests = const [],
    this.ownerRequests = const [],
    this.currentRequest,
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
    bool? isLoading,
    String? error,
    List<RequestModel>? requests,
    List<RequestModel>? ownerRequests,
    RequestModel? currentRequest,
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
      isLoading: isLoading ?? this.isLoading,
      error: error,
      requests: requests ?? this.requests,
      ownerRequests: ownerRequests ?? this.ownerRequests,
      currentRequest: currentRequest ?? this.currentRequest,
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
