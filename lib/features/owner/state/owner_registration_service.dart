import 'package:dio/dio.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/core/api/api_interceptor.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';

class OwnerRegistrationService {
  final ApiClient apiClient;

  OwnerRegistrationService(this.apiClient);

  Dio get _dio => apiClient.dio;

  Future<RegistrationRequestModel?> getOwnerRegistrationRequest() async {
    try {
      final res = await _dio.get("/owner/become-owner");

      print(res.data["data"].toString());

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

      if (e is DioException) {
        print("❌ DIO ERROR: ${e.message}");
        print("❌ STATUS: ${e.response?.statusCode}");
        print("❌ DATA: ${e.response?.data}");
      } else {
        print("❌ ERROR: $e");
      }
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
      if ((id ?? '').isEmpty) {
        throw Exception("Missing registration request id");
      }

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
      final res = await _dio.get("/owner/profile");

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

  Future<bool> updateOwnerProfile({
    String? id,
    String? ownerType,
    String? companyName,
    String? legalName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    String? city,
    String? region,
    String? iin,
    String? serviceDescription,
    String? serviceCities,
  }) async {
    try {
      final res = await _dio.patch(
        "/owner/profile/$id",
        data: {
          "id": id,
          "ownerType": ownerType,
          "companyName": companyName,
          "legalName": legalName,
          if ((firstName ?? '').isNotEmpty) "firstName": firstName,
          if ((lastName ?? '').isNotEmpty) "lastName": lastName,
          if ((phoneNumber ?? '').isNotEmpty) "phoneNumber": phoneNumber,
          if ((email ?? '').isNotEmpty) "email": email,
          if ((city ?? '').isNotEmpty) "city": city,
          if ((region ?? '').isNotEmpty) "region": region,
          if ((iin ?? '').isNotEmpty) "iin": iin,
          if ((serviceDescription ?? '').isNotEmpty)
            "serviceDescription": serviceDescription,
          if ((serviceCities ?? '').isNotEmpty) "serviceCities": serviceCities,
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
}
