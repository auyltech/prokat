import 'dart:io';

import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_helper.dart';
import 'package:prokat/core/api/api_response.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/core/constants/api_routes.dart';
import 'package:prokat/features/owner/models/owner_notification_preferences.dart';

class OwnerRegistrationService {
  final ApiClient apiClient;

  OwnerRegistrationService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<RegistrationRequestModel?> getOwnerRegistrationRequest() async {
    try {
      final res = await _dio.get("/owner/become-owner");

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      if (data == null) return null;

      final json = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);

      return RegistrationRequestModel.fromJson(json);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }

      throw Exception(extractBackendMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> createOwnerRegistrationRequest({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? city,
    String? message,
  }) async {
    try {
      final res = await _dio.post(
        "/owner/become-owner",
        data: {
          if ((firstName ?? '').isNotEmpty) "firstName": firstName,
          if ((lastName ?? '').isNotEmpty) "lastName": lastName,
          if ((phoneNumber ?? '').isNotEmpty) "phoneNumber": phoneNumber,
          if ((email ?? '').isNotEmpty) "email": email,
          if ((city ?? '').isNotEmpty) "city": city,
          if ((message ?? '').isNotEmpty) "message": message,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      final errorMessage = e is DioException
          ? extractBackendMessage(e)
          : e.toString();

      throw Exception(errorMessage);
    }
  }

  Future<bool> updateOwnerRegistrationRequest({
    String? id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? city,
    String? message,
  }) async {
    try {
      // if ((id ?? '').isEmpty) {
      //   throw Exception("Missing registration request id");
      // }

      final res = await _dio.patch(
        "/owner/become-owner/$id",
        data: {
          "id": id,
          if ((firstName ?? '').isNotEmpty) "firstName": firstName,
          if ((lastName ?? '').isNotEmpty) "lastName": lastName,
          if ((phoneNumber ?? '').isNotEmpty) "phoneNumber": phoneNumber,
          if ((email ?? '').isNotEmpty) "email": email,
          if ((city ?? '').isNotEmpty) "city": city,
          if ((message ?? '').isNotEmpty) "message": message,
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> cancelOwnerRegistrationRequest({String? id}) async {
    try {
      if ((id ?? '').isEmpty) {
        throw Exception("Missing registration request id");
      }

      final res = await _dio.delete(
        "/owner/become-owner/$id",
        data: {"id": id, "status": "cancel"},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }
      return false;
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<OwnerProfileModel?> getOwnerProfile() async {
    try {
      final res = await _dio.get(ApiRoutes.ownerProfile);

      final data = res.data is Map<String, dynamic> ? res.data['data'] : null;

      if (data == null) return null;

      final json = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data as Map);

      return OwnerProfileModel.fromJson(json);
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> updateOwnerProfile(OwnerProfileModel profile) async {
    try {
      final res = await _dio.patch(
        ApiRoutes.ownerProfile,
        data: profile.toJson(),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> updateOwnerNotificationSettings(
    OwnerNotificationPreferences preferences,
  ) async {
    try {
      final response = await _dio.patch(
        ApiRoutes.ownerNotificationSettings,
        data: preferences.toPatchJson(),
      );

      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } on DioException catch (error) {
      throw Exception(extractBackendMessage(error));
    } catch (error) {
      throw Exception(error.toString());
    }
  }

  Future<bool> updateOwnerStatus({required OwnerStatus ownerStatus}) async {
    try {
      final res = await _dio.patch(
        "/owner/profile/status",
        data: {"onlineStatus": ownerStatus.name.toUpperCase()},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return true;
      }

      return false;
    } on DioException catch (e) {
      throw Exception(extractBackendMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ApiResponse<void>> uploadProfileImage(File imageFile) async {
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
        ApiRoutes.ownerProfileImage, // Ensure this points to your upload route
        data: formData,
        // Optional: Track upload progress
      );

      return ApiResponse.success(null);
    } catch (e) {
      return ApiResponse.failure(message: "Failed to upload image");
    }
  }
}
