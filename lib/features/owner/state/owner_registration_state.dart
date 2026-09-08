class OwnerRegistrationState {
  final bool isLoading;
  final String? error;
  final String? errorCode;

  OwnerRegistrationState({this.isLoading = false, this.error, this.errorCode});

  OwnerRegistrationState copyWith({
    bool? isLoading,
    String? error,
    String? errorCode,
  }) {
    return OwnerRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      errorCode: errorCode,
    );
  }
}
