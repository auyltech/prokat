import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/providers/api_provider.dart';
import 'package:prokat/features/reviews/state/review_notifier.dart';
import 'package:prokat/features/reviews/state/review_service.dart';
import 'package:prokat/features/reviews/state/review_state.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return ReviewService(apiClient);
});

final reviewByBookingProvider =
    StateNotifierProvider.family<ReviewNotifier, ReviewState, String>((
      ref,
      bookingId,
    ) {
      final service = ref.read(reviewServiceProvider);
      
      return ReviewNotifier(service, bookingId);
    });

