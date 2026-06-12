import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/locations/models/location_search_result.dart';
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

  // Fetch user Addresses
  Future<void> getClientLocations() async {
    try {
      state = state.copyWith(isLoading: true);

      final renterLocations = await api.getClientLocations(mode: "ADDRESS");

      state = state.copyWith(
        renterLocations: renterLocations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Fetch owner equipment locations
  Future<void> getOwnerLocations() async {
    try {
      state = state.copyWith(isLoading: true);

      final ownerLocations = await api.getOwnerLocations();

      state = state.copyWith(ownerLocations: ownerLocations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create new location
  Future<bool> createLocation(LocationModel location) async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await api.createLocation(location);

      if (result.success) {
        state = state.copyWith(isLoading: false);

        if (location.service == "EQUIPMENT") {
          await ref.read(equipmentProvider.notifier).getOwnerEquipment();
        }

        await getClientLocations();

        if (location.service == "ADDRESS" && state.renterLocations.isNotEmpty) {
          selectAddress(state.renterLocations[0]);
        }

        return true;
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update location
  Future<void> updateLocation(String id, LocationModel location) async {
    try {
      await api.updateLocation(id, location);

      if (location.service == "ADDRESS") {
        await getClientLocations();
      } else {
        await getOwnerLocations();
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Delete location
  Future<void> deleteLocation(String id) async {
    try {
      await api.deleteLocation(id);

      await getClientLocations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> searchLocations(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }

    try {
      final results = await api.searchLocation(query);

      state = state.copyWith(suggestions: results);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearSuggestions() {
    state = state.copyWith(suggestions: []);
  }

  void selectAddress(LocationModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  void selectAddressById(String? addressId) {
    final foundAddress = state.renterLocations
        .where((item) => item.id == addressId)
        .firstOrNull;

    state = state.copyWith(selectedAddress: foundAddress);
  }
}
