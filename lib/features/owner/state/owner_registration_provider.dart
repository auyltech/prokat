import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/owner/models/owner_notification_preferences.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/state/owner_profile_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_dependencies.dart';
import 'package:prokat/features/owner/state/owner_registration_request_notifier.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/features/owner/state/owner_registration_state.dart';

export 'owner_registration_dependencies.dart'
    show ownerRegistrationServiceProvider;

final ownerProfileProvider =
    AsyncNotifierProvider<OwnerProfileNotifier, OwnerProfileModel?>(
      OwnerProfileNotifier.new,
    );

final ownerRegistrationRequestProvider =
    AsyncNotifierProvider<
      OwnerRegistrationRequestNotifier,
      RegistrationRequestModel?
    >(OwnerRegistrationRequestNotifier.new);

final ownerRegistrationMutationProvider =
    StateNotifierProvider<
      OwnerRegistrationMutationNotifier,
      OwnerRegistrationState
    >((ref) {
      ref.watch(authProvider.select((auth) => auth.currentUserId));
      return OwnerRegistrationMutationNotifier(
        ref,
        ref.read(ownerRegistrationServiceProvider),
      );
    });

class OwnerRegistrationMutationNotifier
    extends StateNotifier<OwnerRegistrationState> {
  OwnerRegistrationMutationNotifier(this.ref, this.api)
    : super(OwnerRegistrationState());

  final Ref ref;
  final OwnerRegistrationService api;

  Future<bool> createOwnerRegistrationRequest({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? city,
    String? message,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await api.createOwnerRegistrationRequest(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        email: email,
        city: city,
        message: message,
      );
      if (result) {
        await ref.read(ownerRegistrationRequestProvider.notifier).refresh();
      }
      state = state.copyWith(isLoading: false);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final id = ref.read(ownerRegistrationRequestProvider).valueOrNull?.id;
      final result = await api.updateOwnerRegistrationRequest(
        id: id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        email: email,
        city: city,
        message: message,
      );
      if (result) {
        await ref.read(ownerRegistrationRequestProvider.notifier).refresh();
      }
      state = state.copyWith(isLoading: false);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> updateOwnerProfile(
    OwnerProfileModel profile, {
    bool submitForReview = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await api.updateOwnerProfile(
        profile,
        submitForReview: submitForReview,
      );
      if (result) await ref.read(ownerProfileProvider.notifier).refresh();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> updateOwnerNotificationSettings(
    OwnerNotificationPreferences preferences,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await api.updateOwnerNotificationSettings(preferences);
      if (result) await ref.read(ownerProfileProvider.notifier).refresh();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> updateOwnerStatus({required OwnerStatus ownerStatus}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await api.updateOwnerStatus(ownerStatus: ownerStatus);
      if (result) await ref.read(ownerProfileProvider.notifier).refresh();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }

  Future<bool> uploadProfileImage(File file) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await api.uploadProfileImage(file);
      if (result.success) {
        await ref.read(ownerProfileProvider.notifier).refresh();
      }
      state = state.copyWith(isLoading: false);
      return result.success;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return false;
    }
  }
}
