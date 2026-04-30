import 'package:prokat/features/owner/models/registration_request_model.dart';

class OwnerRegistrationState {
  final bool isLoading;
  final String? error;

  final RegistrationRequestModel? registrationRequest;

  OwnerRegistrationState({
    this.isLoading = false,
    this.error,
    this.registrationRequest,
  });

  OwnerRegistrationState copyWith({
    bool? isLoading,
    String? Function()? error,
    RegistrationRequestModel? Function()? registrationRequest,
  }) {
    return OwnerRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      registrationRequest: registrationRequest != null
          ? registrationRequest()
          : this.registrationRequest,
    );
  }
}
