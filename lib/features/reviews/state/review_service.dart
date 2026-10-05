import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/features/reviews/models/review_model.dart';

class ReviewService {
  final ApiClient apiClient;

  final String? companyId;
  ReviewService(this.apiClient, {this.companyId});
  String get prefix => companyId == null ? '' : '/company-profile/$companyId';

  Dio get _dio => apiClient.dio;

  Future<ReviewModel> createReview({
    required String bookingId,
    required String revieweeId,
    required int stars,
    String? comment,
  }) async {
    try {
      final res = await _dio.post(
        '$prefix/reviews',
        data: {
          'bookingId': bookingId,
          'revieweeId': revieweeId,
          'ratingStars': stars,
          if ((comment ?? '').trim().isNotEmpty) 'comment': comment,
        },
      );

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      final json = data is Map<String, dynamic>
          ? data
          : data is Map
          ? Map<String, dynamic>.from(data)
          : null;

      if (json == null) {
        throw Exception('Failed to create review');
      }

      return ReviewModel.fromJson(json);
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    }
  }
}
