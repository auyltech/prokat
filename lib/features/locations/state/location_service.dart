import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/api_routes.dart';
import '../models/location_model.dart';
import '../models/location_search_result.dart';

class LocationService {
  final ApiClient apiClient;

  LocationService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<List<LocationModel>> getRenterLocations({String? mode}) async {
    try {
      final response = await _dio.get(ApiRoutes.locations);

      return (response.data["data"] as List)
          .map((e) => LocationModel.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<LocationModel>> getOwnerLocations({String? mode}) async {
    try {
      final response = await _dio.get(ApiRoutes.ownerLocations);

      return (response.data["data"] as List)
          .map((e) => LocationModel.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ApiResponse<LocationModel?>> createLocation(
    LocationModel location,
  ) async {
    try {
      final response = await _dio.post('/locations', data: location.toJson());

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

  Future<LocationModel> updateLocation(
    String id,
    LocationModel location,
  ) async {
    final response = await _dio.patch(
      '/locations/$id',
      data: location.toJson(),
    );

    return LocationModel.fromJson(response.data);
  }

  Future<void> deleteLocation(String id) async {
    await _dio.delete('/locations/$id');
  }

  /// Search address (Mapbox or backend proxy)
  Future<List<LocationSearchResult>> searchLocation(String query) async {
    final response = await _dio.get(
      '/locations/search',
      queryParameters: {"query": query},
    );

    return (response.data as List).map((e) {
      return LocationSearchResult(
        name: e['name'] ?? '',
        street: e['street'] ?? '',
        city: e['city'],
        country: e['country'],
        longitude: (e['longitude'] as num).toDouble(),
        latitude: (e['latitude'] as num).toDouble(),
      );
    }).toList();
  }

  /// Reverse geocode coordinates → address
  Future<LocationSearchResult?> reverseGeocode(
    double longitude,
    double latitude,
  ) async {
    try {
      final response = await _dio.get(
        '/locations/reverse',
        queryParameters: {"longitude": longitude, "latitude": latitude},
      );

      if (response.statusCode != 200) {
        return null;
      }

      if (response.data == null ||
          (response.data is List && response.data.isEmpty)) {
        return null;
      }

      final data = response.data;

      return LocationSearchResult(
        name: data['name'],
        street: data['street'],
        city: data['city'],
        country: data['country'],
        longitude: longitude,
        latitude: latitude,
      );
    } catch (e) {
      return null;
    }
  }
}
