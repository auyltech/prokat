import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';

import '../models/location_model.dart';
import '../models/location_search_result.dart';

class LocationState {
  final FetchStatus fetchStatus;
  final PaginationStatus paginationStatus;

  final DateTime? lastFetchedAt;
  final AppError? fetchError;

  final Set<Mutation> activeActions;

  final String? city;

  final List<LocationModel> clientLocations;
  final List<LocationModel> ownerLocations;

  final LocationModel? selectedAddress;
  final List<LocationSearchResult> suggestions;

  const LocationState({
    this.fetchStatus = FetchStatus.initial,
    this.paginationStatus = PaginationStatus.idle,
    this.lastFetchedAt,
    this.fetchError,
    this.activeActions = const {},

    this.city,

    this.clientLocations = const [],
    this.ownerLocations = const [],
    this.selectedAddress,
    this.suggestions = const [],
  });

  bool get isFetching {
    return [FetchStatus.loading, FetchStatus.refreshing].contains(fetchStatus);
  }

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

  LocationState copyWith({
    FetchStatus? fetchStatus,
    PaginationStatus? paginationStatus,
    DateTime? lastFetchedAt,
    AppError? fetchError,
    Set<Mutation>? activeActions,

    String? city,
    List<LocationModel>? clientLocations,
    List<LocationModel>? ownerLocations,
    List<LocationSearchResult>? suggestions,
    LocationModel? selectedAddress,
  }) {
    return LocationState(
      fetchStatus: fetchStatus ?? this.fetchStatus,
      paginationStatus: paginationStatus ?? this.paginationStatus,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      fetchError: fetchError,
      activeActions: activeActions ?? this.activeActions,

      city: city ?? this.city,
      clientLocations: clientLocations ?? this.clientLocations,
      ownerLocations: ownerLocations ?? this.ownerLocations,

      suggestions: suggestions ?? this.suggestions,
      selectedAddress: selectedAddress ?? this.selectedAddress,
    );
  }
}
