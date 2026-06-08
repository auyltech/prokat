class BookingChatActionState {
  final bool isSubmitting;
  final String? submitId;

  final String? error;

  const BookingChatActionState({
    this.isSubmitting = false,
    this.error,
    this.submitId,
  });

  BookingChatActionState copyWith({
    bool? isSubmitting,
    String? submitId,
    String? error,
  }) {
    return BookingChatActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitId: submitId,
      error: error,
    );
  }
}
