import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/reviews/state/review_service.dart';
import 'package:prokat/features/reviews/state/review_state.dart';

bool _looksLikeDuplicateReview(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('already') ||
      normalized.contains('exists') ||
      normalized.contains('duplicate');
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewService service;
  final String bookingId;

  ReviewNotifier(this.service, this.bookingId) : super(const ReviewState());

  Future<bool> createReview({
    required String revieweeId,
    required int stars,
    String? comment,
  }) async {
    try {
      state = state.copyWith(isSubmitting: true, error: null);

      final result = await service.createReview(
        bookingId: bookingId,
        revieweeId: revieweeId,
        stars: stars,
        comment: comment,
      );

      state = state.copyWith(
        isSubmitting: false,
        hasSubmitted: true,
        lastReview: result,
        error: null,
      );

      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (_looksLikeDuplicateReview(message)) {
        state = state.copyWith(
          isSubmitting: false,
          hasSubmitted: true,
          error: null,
        );
      } else {
        state = state.copyWith(isSubmitting: false, error: message);
      }

      return false;
    }
  }
}
