import 'package:prokat/core/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'dart:io';

class UserProfileService {
  final ApiClient apiClient;

  UserProfileService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<UserProfileModel?> getUserProfile() async {
    try {
      final res = await _dio.get(ApiRoutes.profile);

      return UserProfileModel.fromJson(res.data['data']);
    } catch (e) {
      return null;
    }
  }

  Future<ApiResponse<UserProfileModel?>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? profileImageUrl,
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

  Future<UserProfileModel?> updateUserName(String? username) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.username,
        data: {"username": ?username},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserProfileModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserProfileModel?> selectCategory(String? selectedCategoryId) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.userCategory,
        data: {"selectedCategoryId": ?selectedCategoryId},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserProfileModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserProfileModel?> selectAddress(String? addressId) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.userAddress,
        data: {"addressId": ?addressId},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserProfileModel.fromJson(res.data['data']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserProfileModel?> selectCityRegion(
    String? city,
    String? region,
  ) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.userCityRegion,
        data: {"city": ?city, "region": ?region},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return UserProfileModel.fromJson(res.data['data']);
      }

      return null;
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
}
