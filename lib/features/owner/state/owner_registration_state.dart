class OwnerRegistrationState {
  final bool isLoading;
  final String? error;

  OwnerRegistrationState({this.isLoading = false, this.error});

  OwnerRegistrationState copyWith({bool? isLoading, String? error}) {
    return OwnerRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
