import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/state/user_profile_service.dart';
import 'package:prokat/features/user/state/user_profile_state.dart';
import 'dart:io';

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier(this.ref, this.service) : super(UserProfileState());

  final Ref ref;
  final UserProfileService service;

  void setFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
  }

  void setLastName(String lastName) {
    state = state.copyWith(lastName: lastName);
  }

  void setDarkMode(String darkMode) {
    state = state.copyWith(darkMode: darkMode);
  }

  Future<bool> getUserProfile() async {
    try {
      state = state.copyWith(isLoading: true);

      final data = await service.getUserProfile();

      state = state.copyWith(isLoading: false, userProfile: () => data);

      if (data == null) {
        return false;
      }

      ref.read(locationProvider.notifier).selectCity(data.city ?? "");
      ref
          .read(categoriesProvider.notifier)
          .selectCategoryById(data.selectedCategoryId);
      ref
          .read(locationProvider.notifier)
          .selectAddressById(data.selectedAddressId);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        userProfile: () => null,
        error: e.toString(),
      );

      return false;
    }
  }

  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? phoneCountryCode,
    String? profileImageUrl,
    String? darkMode,
    String? selectedAddressId,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        profileImageUrl: profileImageUrl,
        darkMode: darkMode,
        selectedAddressId: selectedAddressId,
      );

      state = state.copyWith(isLoading: false);
      if (result.success) {
        await getUserProfile();
      }

      return result.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> selectCategory(String selectedCategoryId) async {
    try {
      state = state.copyWith(isLoading: true);

      final updated = await service.selectCategory(selectedCategoryId);

      if (updated != null) {
        await getUserProfile();

        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> selectAddress(String addressId) async {
    try {
      state = state.copyWith(isLoading: true);

      final updated = await service.selectAddress(addressId);

      if (updated != null) {
        await getUserProfile();

        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> selectCityRegion(String city, String region) async {
    try {
      state = state.copyWith(isLoading: true);

      final updated = await service.selectCityRegion(city, region);

      if (updated != null) {
        await getUserProfile();

        return true;
      }

      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      state = state.copyWith(isLoading: true);

      final response = await service.uploadProfileImage(imageFile);

      await service.getUserProfile();

      state = state.copyWith(isLoading: false);

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());

      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await service.deleteAccount();

      state = state.copyWith(isLoading: false);

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
