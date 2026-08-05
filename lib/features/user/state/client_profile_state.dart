class ClientProfileState {
  final bool isLoading;
  final String? error;

  ClientProfileState({this.isLoading = false, this.error});

  ClientProfileState copyWith({bool? isLoading, String? error}) {
    return ClientProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
