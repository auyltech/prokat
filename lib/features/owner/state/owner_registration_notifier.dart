import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/features/owner/state/owner_registration_state.dart';

class OwnerRegistrationNotifier extends StateNotifier<OwnerRegistrationState> {
  final OwnerRegistrationService api;

  OwnerRegistrationNotifier(this.api) : super(OwnerRegistrationState());

  Future<void> getRegistrationRequest() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final data = await api.getOwnerRegistrationRequest();

      state = state.copyWith(isLoading: false, registrationRequest: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createOwnerRegistrationRequest({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? city,
    String? message,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final created = await api.createOwnerRegistrationRequest(
        firstName: firstName,
        lastName: lastName,
        city: city,
        email: email,
        message: message,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(isLoading: false);

      if (created == true) {
        await getRegistrationRequest();

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateOwnerRegistrationRequest({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? city,
    String? message,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final id = state.registrationRequest?.id;

      final updated = await api.updateOwnerRegistrationRequest(
        id: id,
        firstName: firstName,
        lastName: lastName,
        city: city,
        email: email,
        message: message,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(isLoading: false);

      if (updated == true) {
        await getRegistrationRequest();

        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> getOwnerProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final data = await api.getOwnerProfile();

      state = state.copyWith(isLoading: false, ownerProfile: data);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<bool> updateOwnerProfile(OwnerProfileModel updatedProfile) async {
    try {
      return false;
    } catch (error) {
      return false;
    }
  }

  Future<bool> updateOwnerStatus({required OwnerStatus ownerStatus}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await api.updateOwnerStatus(ownerStatus: ownerStatus);

      if (result) {
        await getOwnerProfile();
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
