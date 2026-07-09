import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/billing/models/account_balance_model.dart';
import 'package:prokat/features/billing/models/pricing_tier_model.dart';
import 'package:prokat/features/billing/models/transaction_model.dart';
import 'package:prokat/features/billing/models/volume_discount_model.dart';

class BillingService {
  final ApiClient apiClient;

  BillingService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<AccountBalanceModel>> getOwnerBalance() async {
    try {
      final response = await _dio.get(ApiRoutes.balance);
      return handleApiResponse<AccountBalanceModel>(
        response: response,
        parser: (data) {
          final itemsJson = data["data"];

          if (itemsJson is! Map<String, dynamic>) {
            throw FormatException("Invalid account balance");
          }

          return AccountBalanceModel.fromJson(itemsJson);
        },
        fallbackMessage: "Failed to load account balance",
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
        error: "Failed to load account balance",
      );
    }
  }

  Future<ApiResponse<List<TransactionModel>>> getOwnerTransactions() async {
    try {
      final response = await _dio.get(ApiRoutes.transactions);

      return handleApiResponse<List<TransactionModel>>(
        response: response,
        parser: (data) => TransactionModel.fromJsonList(data["data"]),
        fallbackMessage: "Failed to load transactions",
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
        error: "Failed to load transactions",
      );
    }
  }

  Future<ApiResponse<List<PricingTierModel>>> getPricingTiers() async {
    try {
      final response = await _dio.get(ApiRoutes.priceTiers);

      return handleApiResponse<List<PricingTierModel>>(
        response: response,
        parser: (data) => PricingTierModel.fromJsonList(data["data"]),
        fallbackMessage: "Failed to load price tiers",
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
        error: "Failed to load pricing tiers",
      );
    }
  }

  Future<ApiResponse<List<VolumeDiscountModel>>> getVolumeDiscounts() async {
    try {
      final response = await _dio.get(ApiRoutes.volumeDiscount);

      return handleApiResponse<List<VolumeDiscountModel>>(
        response: response,
        parser: (data) => VolumeDiscountModel.fromJsonList(data["data"]),
        fallbackMessage: "Failed to load volume discount",
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

  Future<ApiResponse<void>> topUpBalance({required String id}) async {
    try {
      final response = await _dio.post(
        ApiRoutes.topUpBalance,
        data: {"id": id},
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Transaction processed successfully",
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
