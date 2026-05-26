class BookingChatActionState {
  final bool isSubmitting;
  final String? error;

  const BookingChatActionState({this.isSubmitting = false, this.error});

  BookingChatActionState copyWith({bool? isSubmitting, String? error}) {
    return BookingChatActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

