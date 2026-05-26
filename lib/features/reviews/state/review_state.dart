import 'package:prokat/features/reviews/models/review_model.dart';

class ReviewState {
  final bool isSubmitting;
  final String? error;
  final bool hasSubmitted;

  final ReviewModel? lastReview;

  const ReviewState({
    this.isSubmitting = false,
    this.error,
    this.hasSubmitted = false,
    this.lastReview,
  });

  ReviewState copyWith({
    bool? isSubmitting,
    String? error,
    bool? hasSubmitted,
    ReviewModel? lastReview,
  }) {
    return ReviewState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      lastReview: lastReview ?? this.lastReview,
    );
  }
}
