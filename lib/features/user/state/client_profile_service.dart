import 'package:prokat/core/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/core/errors/api_exception.dart';
import 'package:prokat/features/user/models/client_notification_preferences.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'dart:io';

class ClientProfileService {
  final ApiClient apiClient;

  ClientProfileService(this.apiClient);

  Dio get _dio => apiClient.dio;

  UserProfileModel? _profileFromBody(dynamic body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is! Map) return null;
    try {
      return UserProfileModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<UserProfileModel?> _profileAfterUpdate(Response res) async {
    if (res.statusCode != 200 && res.statusCode != 201) {
      return null;
    }

    try {
      return _profileFromBody(res.data) ?? await getUserProfile();
    } catch (_) {
      // PATCH already succeeded; caller refreshes the profile next.
      return UserProfileModel();
    }
  }

  Future<UserProfileModel?> getUserProfile() async {
    try {
      final res = await _dio.get(ApiRoutes.profile);

      return UserProfileModel.fromJson(res.data['data']);
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    }
  }

  Future<ApiResponse<UserProfileModel?>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    String? language,
    String? darkMode,
    String? selectedCategoryId,
    String? selectedAddressId,
  }) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.profile,
        data: {
          "firstName": ?firstName,
          "lastName": ?lastName,
          "profileImageUrl": ?profileImageUrl,
          "darkMode": ?darkMode,
          "language": ?language,
          "selectedCategoryId": ?selectedCategoryId,
          "selectedAddressId": ?selectedAddressId,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiResponse.success(null);
      }

      return ApiResponse.failure(message: res.statusCode.toString());
    } catch (e) {
      return ApiResponse.failure(message: extractBackendMessage(e));
    }
  }

  Future<void> updateUserSettings({required String language}) async {
    try {
      await _dio.patch(
        ApiRoutes.userSettings,
        data: {'language': language},
      );
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    }
  }

  Future<ApiResponse<void>> updateClientNotificationSettings(
    ClientNotificationPreferences preferences,
  ) async {
    try {
      final response = await _dio.patch(
        ApiRoutes.clientNotificationSettings,
        data: preferences.toPatchJson(),
      );

      return handleEmptyApiResponse(
        response: response,
        fallbackMessage: "Settings updated",
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

  Future<UserProfileModel?> selectCategory(String? selectedCategoryId) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.userCategory,
        data: {"selectedCategoryId": ?selectedCategoryId},
      );

      return await _profileAfterUpdate(res);
    } catch (error) {
      return null;
    }
  }

  Future<UserProfileModel?> selectAddress(String? addressId) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.userAddress,
        data: {"addressId": ?addressId},
      );

      return await _profileAfterUpdate(res);
    } catch (error) {
      return null;
    }
  }

  Future<UserProfileModel?> selectCityRegion({
    String? city,
    String? region,
  }) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.userCityRegion,
        data: {"city": ?city, "region": ?region},
      );

      return await _profileAfterUpdate(res);
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        // "profileImage" must match the key expected by your Node.js Multer setup
        "profileImage": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
        // Optional: you can add other fields here
        "type": "avatar",
      });

      // 2. Send the POST request
      await _dio.post(
        ApiRoutes.userProfileImage, // Ensure this points to your upload route
        data: formData,
        // Optional: Track upload progress
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final res = await _dio.post(ApiRoutes.deleteAccount);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (error) {
      return false;
    }
  }
}
