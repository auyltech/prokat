import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';

class OwnerRegistrationState {
  final bool isLoading;
  final String? error;

  final RegistrationRequestModel? registrationRequest;
  final OwnerProfileModel? ownerProfile;

  OwnerRegistrationState({
    this.isLoading = false,
    this.error,
    this.registrationRequest,
    this.ownerProfile,
  });

  OwnerRegistrationState copyWith({
    bool? isLoading,
    String? error,
    OwnerProfileModel? ownerProfile,
    RegistrationRequestModel? registrationRequest,
    bool clearOwnerProfile = false,
    bool clearRegistrationRequest = false,
  }) {
    return OwnerRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ownerProfile: clearOwnerProfile
          ? null
          : ownerProfile ?? this.ownerProfile,
      registrationRequest: clearRegistrationRequest
          ? null
          : registrationRequest ?? this.registrationRequest,
    );
  }
}
