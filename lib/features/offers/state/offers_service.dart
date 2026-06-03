import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:dio/dio.dart';

class OffersService {
  final ApiClient apiClient;

  OffersService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<OfferModel>>> getClientOffers() async {
    try {
      final response = await _dio.get('/offers');

      return handleApiResponse<List<OfferModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected offers list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid offer item");
            }

            return OfferModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load offers",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<OfferModel>>> getOwnerOffers() async {
    try {
      final response = await _dio.get('/offers/owner');

      return handleApiResponse<List<OfferModel>>(
        response: response,
        parser: (data) {
          if (data is! List) {
            throw FormatException("Expected offers list");
          }

          return data.map((item) {
            if (item is! Map<String, dynamic>) {
              throw FormatException("Invalid offer item");
            }

            return OfferModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load offers",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> createOffer({
    required String requestId,
    required String equipmentId,
    required int price,
    required String priceRate,
    String? comment,
  }) async {
    try {
      final response = await _dio.post(
        '/offers',
        data: {
          "requestId": requestId,
          "equipmentId": equipmentId,
          "price": price,
          "priceRate": priceRate,
          "comment": comment,
        },
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Offer created",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> acceptOffer({required String id}) async {
    try {
      final response = await _dio.post('/offers/$id/accept', data: {"id": id});

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Booking created",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> rejectOffer({required String id}) async {
    try {
      final response = await _dio.post('/offers/$id/reject', data: {"id": id});

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Booking created",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> cancelOffer({required String id}) async {
    try {
      final response = await _dio.patch('/offers/$id/cancel', data: {"id": id});

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Booking created",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: exception.data ?? error,
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }
}
