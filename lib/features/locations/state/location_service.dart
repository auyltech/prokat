import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/core/constants/map_constants.dart';
import 'package:prokat/core/errors/api_exception.dart';

import '../models/location_model.dart';
import '../models/location_search_result.dart';

class LocationService {
  final ApiClient apiClient;

  LocationService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<ApiResponse<List<LocationModel>>> getClientLocations({
    String? mode,
  }) async {
    try {
      final response = await _dio.get(ApiRoutes.locations);

      return handleApiResponse<List<LocationModel>>(
        response: response,
        parser: (data) {
          final itemsJson = data["data"];

          if (itemsJson is! List) {
            throw const FormatException("Expected locations list");
          }

          return itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException("Invalid location item");
            }

            return LocationModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load locations",
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
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }

  Future<ApiResponse<List<LocationModel>>> getOwnerLocations({
    String? mode,
  }) async {
    try {
      final response = await _dio.get(ApiRoutes.ownerLocations);

      return handleApiResponse<List<LocationModel>>(
        response: response,
        parser: (data) {
          final itemsJson = data["data"];

          if (itemsJson is! List) {
            throw const FormatException("Expected locations list");
          }

          return itemsJson.map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException("Invalid location item");
            }

            return LocationModel.fromJson(item);
          }).toList();
        },
        fallbackMessage: "Failed to load locations",
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
    } catch (error) {
      return ApiResponse.failure(
        message: "Unexpected error",
        error: error.toString(),
      );
    }
  }

  Future<ApiResponse<LocationModel?>> createLocation(
    LocationModel location,
  ) async {
    try {
      final response = await _dio.post('/locations', data: location.toJson());

      return handleApiResponse<LocationModel>(
        response: response,
        parser: (data) {
          final rawJson = data["data"];

          if (rawJson is! Map<String, dynamic>) {
            throw const FormatException("Invalid location item");
          }

          return LocationModel.fromJson(rawJson);
        },
        fallbackMessage: "Failed to load locations",
      );
    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid information";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      } else if (e.response?.data != null) {
        message = extractBackendMessage(e.response?.data);
      }

      return ApiResponse.failure(
        message: message,
        error: e.response?.data?["error"]?.toString(),
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "CreateLocation_Unexpected_Error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<LocationModel?>> updateLocation(
    String id,
    LocationModel location,
  ) async {
    try {
      final response = await _dio.patch(
        '/locations/$id',
        data: location.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(null, message: "Address created");
      }

      final message = extractBackendMessage(response.data);

      throw Exception(message);
    } on DioException catch (e) {
      String message = "Something went wrong";

      if (e.response?.statusCode == 400) {
        message = "Missing or invalid information";
      } else if (e.response?.statusCode == 500) {
        message = "Server Error";
      } else if (e.response?.data != null) {
        message = extractBackendMessage(e.response?.data);
      }

      return ApiResponse.failure(
        message: message,
        error: e.response?.data?["error"]?.toString(),
      );
    } catch (e) {
      return ApiResponse.failure(
        message: "CreateLocation_Unexpected_Error",
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<void>> deleteLocation(String id) async {
    try {
      final response = await _dio.delete('${ApiRoutes.locations}/$id');
      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Address deleted",
      );
    } on DioException catch (error) {
      return handleDioException(
        error,
        fallbackMessage: "Failed to delete address",
      );
    } catch (error) {
      return handleUnknownException(
        error,
        fallbackMessage: "Failed to delete address",
      );
    }
  }

  Future<List<LocationSearchResult>> searchLocation(
    String query, {
    double? proximityLongitude,
    double? proximityLatitude,
  }) async {
    final response = await _dio.get(
      ApiRoutes.locationSearch,
      queryParameters: {
        "query": query,
        "proximityLongitude":
            proximityLongitude ?? MapConstants.defaultLongitude,
        "proximityLatitude": proximityLatitude ?? MapConstants.defaultLatitude,
      },
    );

    return (response.data as List).map((e) {
      if (e is! Map<String, dynamic>) {
        throw const FormatException("Invalid location search item");
      }
      return LocationSearchResult.fromJson(e);
    }).toList();
  }

  Future<LocationSearchResult?> reverseGeocode(
    double longitude,
    double latitude,
  ) async {
    try {
      final response = await _dio.get(
        ApiRoutes.locationReverse,
        queryParameters: {
          "longitude": longitude,
          "latitude": latitude,
          "proximityLongitude": longitude,
          "proximityLatitude": latitude,
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      if (response.data == null ||
          (response.data is List && response.data.isEmpty)) {
        return null;
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return null;
      }

      return LocationSearchResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
