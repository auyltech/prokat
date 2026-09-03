import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/offers/models/offer_model.dart';
import 'package:prokat/features/offers/models/offer_query.dart';
import 'package:prokat/features/bookings/models/query_result.dart';
import 'package:dio/dio.dart';

class OffersService {
  final ApiClient apiClient;

  OffersService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<QueryResult<OfferModel>>> getClientOffers({
    required int page,
    required int itemsPerPage,
    OfferListFilter? filter,
    String? requestId,
  }) {
    return _getOffers(
      path: '/offers',
      page: page,
      itemsPerPage: itemsPerPage,
      filter: filter,
      requestId: requestId,
    );
  }

  Future<ApiResponse<QueryResult<OfferModel>>> _getOffers({
    required String path,
    required int page,
    required int itemsPerPage,
    OfferListFilter? filter,
    String? requestId,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: {
          'page': page,
          'itemsPerPage': itemsPerPage,
          if (filter != null) 'status': filter.apiValue,
          if ((requestId ?? '').trim().isNotEmpty) 'requestId': requestId,
        },
      );

      return handleApiResponse<QueryResult<OfferModel>>(
        response: response,
        parser: (data) {
          final payload = data is Map<String, dynamic> && data['data'] is Map
              ? Map<String, dynamic>.from(data['data'] as Map)
              : Map<String, dynamic>.from(data as Map);
          final itemsJson = payload['items'] ?? payload['data'];

          if (itemsJson is! List) {
            throw const FormatException("Expected offers list");
          }

          final items = itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException("Invalid offer item");
            }

            return OfferModel.fromJson(item);
          }).toList();

          return QueryResult(
            items: items,
            page: (payload['page'] as num?)?.toInt() ?? page,
            itemsPerPage:
                (payload['itemsPerPage'] as num?)?.toInt() ?? itemsPerPage,
            count: (payload['count'] as num?)?.toInt() ?? items.length,
          );
        },
        fallbackMessage: "Failed to load offers",
      );
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);

      return ApiResponse.failure(
        message: exception.message.isNotEmpty
            ? exception.message
            : "Request failed",
        error: (exception.data ?? error).toString(),
        statusCode: exception.statusCode,
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<QueryResult<OfferModel>>> getOwnerOffers({
    required int page,
    required int itemsPerPage,
    OfferListFilter? filter,
    String? requestId,
  }) {
    return _getOffers(
      path: '/offers/owner',
      page: page,
      itemsPerPage: itemsPerPage,
      filter: filter,
      requestId: requestId,
    );
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
      return handleDioException(error, fallbackMessage: "Request failed");
    } catch (e) {
      return handleUnknownException(e, fallbackMessage: "Unexpected error");
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
        error: (exception.data ?? error).toString(),
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
        error: (exception.data ?? error).toString(),
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
        error: (exception.data ?? error).toString(),
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
