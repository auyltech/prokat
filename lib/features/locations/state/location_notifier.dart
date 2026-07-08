import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/fetch_status.dart';
import 'package:prokat/core/errors/app_error.dart';
import 'package:prokat/core/mutation/mutation_model.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
import 'package:prokat/features/requests/providers/request_mutation_provider.dart';
import '../models/location_model.dart';
import 'location_service.dart';
import 'location_state.dart';

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService api;
  final Ref ref;

  LocationNotifier(this.api, this.ref) : super(const LocationState());

  List<LocationSearchResult> suggestions = [];

  void selectCity(String city) {
    state = state.copyWith(city: city);
  }

  void _startAction(String actionId) {
    state = state.copyWith(
      activeActions: {
        ...state.activeActions,
        Mutation(id: actionId, status: MutationStatus.submitting),
      },
    );
  }

  void _finishAction(String actionId, {AppError? error}) {
    final actions = {...state.activeActions};

    if (error == null) {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));
    } else {
      actions.remove(Mutation(id: actionId, status: MutationStatus.submitting));

      final action = Mutation(
        id: actionId,
        status: MutationStatus.error,
        error: error,
      );

      actions.add(action);
    }

    state = state.copyWith(activeActions: actions);
  }

  bool isActionActive(String actionId) {
    return state.activeActions.contains(
      Mutation(id: actionId, status: MutationStatus.submitting),
    );
  }

  // Fetch user Addresses
  Future<void> getClientLocations() async {
    try {
      final hasData = state.clientLocations.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getClientLocations(mode: "ADDRESS");

      state = state.copyWith(
        clientLocations: result.data,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "LOCATIONS_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.clientLocations.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "LOCATIONS_FETCH_FAILED",
        ),
      );
    }
  }

  // Fetch owner equipment locations
  Future<void> getOwnerLocations() async {
    try {
      final hasData = state.ownerLocations.isNotEmpty;

      state = state.copyWith(
        fetchStatus: hasData ? FetchStatus.refreshing : FetchStatus.loading,
        fetchError: null,
      );

      final result = await api.getOwnerLocations();

      state = state.copyWith(
        ownerLocations: result.data,
        fetchStatus: result.data == null
            ? FetchStatus.error
            : result.data?.isEmpty == true
            ? FetchStatus.empty
            : FetchStatus.success,
        lastFetchedAt: DateTime.now(),
        fetchError: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                message: result.error.toString(),
                code: "BOOKING_FETCH_FAILED",
              ),
      );
    } catch (error) {
      state = state.copyWith(
        fetchStatus: state.ownerLocations.isEmpty
            ? FetchStatus.error
            : FetchStatus.success,
        fetchError: AppError(
          type: ErrorType.unknown,
          message: error.toString(),
          code: "BOOKING_FETCH_FAILED",
        ),
      );
    }
  }

  // Create new location
  Future<bool> createLocation(LocationModel location, String from) async {
    const actionId = "location:create";
    try {
      _startAction(actionId);

      final result = await api.createLocation(location);

      _finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (result.success) {
        if (location.service == "EQUIPMENT") {
          ref.read(ownerEquipmentProvider.notifier).refresh();
        } else {
          getClientLocations();
        }

        if (location.service == "ADDRESS" &&
            result.data != null &&
            state.clientLocations.isNotEmpty) {
          // selectAddress(state.clientLocations[0]);
          selectAddress(result.data ?? state.clientLocations[0]);

          if (from == "create_request") {
            ref
                .read(requestMutationProvider.notifier)
                .selectLocation(result.data ?? state.clientLocations[0]);
          } else if (from == "create_booking") {}
        }

        return true;
      }

      return false;
    } catch (error) {
      _finishAction(actionId);

      return false;
    }
  }

  // Update location
  Future<bool> updateLocation(String id, LocationModel location) async {
    final actionId = "location:$id:create";
    try {
      _startAction(actionId);

      final result = await api.updateLocation(id, location);

      _finishAction(
        actionId,
        error: result.success
            ? null
            : AppError(
                type: ErrorType.unknown,
                code: "",
                message: result.message,
              ),
      );

      if (location.service == "ADDRESS") {
        getClientLocations();
      } else {
        getOwnerLocations();
      }

      return result.success;
    } catch (error) {
      _finishAction(actionId);

      return false;
    }
  }

  // Delete location
  Future<void> deleteLocation(String id) async {
    await api.deleteLocation(id);

    await getClientLocations();
  }

  Future<void> searchLocations(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }

    try {
      final results = await api.searchLocation(query);

      state = state.copyWith(suggestions: results);
    } catch (e) {}
  }

  void clearSuggestions() {
    state = state.copyWith(suggestions: []);
  }

  void selectAddress(LocationModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  void selectAddressById(String? addressId) {
    final foundAddress = state.clientLocations
        .where((item) => item.id == addressId)
        .firstOrNull;

    state = state.copyWith(selectedAddress: foundAddress);
  }
}
