import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/user/models/client_notification_preferences.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/state/client_profile_service.dart';
import 'package:prokat/features/user/state/client_profile_state.dart';

class ClientProfileMutationNotifier extends StateNotifier<ClientProfileState> {
  ClientProfileMutationNotifier(this.ref, this.service)
    : super(ClientProfileState());

  final Ref ref;
  final ClientProfileService service;

  Future<void> _refreshProfile() =>
      ref.read(clientProfileProvider.notifier).refresh();

  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? phoneCountryCode,
    String? profileImageUrl,
    String? darkMode,
    String? language,
    String? selectedAddressId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await service.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        profileImageUrl: profileImageUrl,
        darkMode: darkMode,
        language: language,
        selectedAddressId: selectedAddressId,
      );
      if (result.success) await _refreshProfile();
      state = state.copyWith(isLoading: false);
      return result.success;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> updateClientNotificationSettings(
    ClientNotificationPreferences preferences,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await service.updateClientNotificationSettings(
        preferences,
      );
      if (result.success) await _refreshProfile();
      state = state.copyWith(isLoading: false);
      return result.success;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> selectCategory(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await service.selectCategory(id);
      if (updated == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      await _refreshProfile();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> selectAddress(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await service.selectAddress(id);
      if (updated == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      await _refreshProfile();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> selectCityRegion({String? city, String? region}) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await service.selectCityRegion(
        city: city,
        region: region,
      );
      if (updated == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      await _refreshProfile();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> uploadProfileImage(File file) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await service.uploadProfileImage(file);
      if (result) await _refreshProfile();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await service.deleteAccount();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }
}
