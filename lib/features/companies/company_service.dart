import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/api/api_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

import 'company_models.dart';

class CompanyApiException implements Exception {
  final int? statusCode;
  final String code;
  final String? message;
  const CompanyApiException(this.statusCode, this.code, [this.message]);
}

class CompanyService {
  final Dio dio;
  CompanyService(this.dio);
  Future<Map<String, dynamic>> billing(String id) async =>
      _data(await dio.get('/companies/${Uri.encodeComponent(id)}/billing'));
  Future<void> setOnline(String id, bool online) async {
    _data(
      await dio.patch(
        '/companies/${Uri.encodeComponent(id)}/billing/status',
        data: {'online': online},
      ),
    );
  }

  Future<void> visibility(String id, bool visible) async {
    _data(
      await dio.patch('/companies/$id/visibility', data: {'visible': visible}),
    );
  }

  Future<void> availability(String id, String equipmentId, bool busy) async {
    _data(
      await dio.patch(
        '/companies/$id/fleet/$equipmentId/availability',
        data: {'busy': busy},
      ),
    );
  }

  Future<void> archive(String id, String equipmentId) async {
    _data(await dio.delete('/companies/$id/fleet/$equipmentId'));
  }

  Future<void> inviteDispatcher(String companyId, String phoneNumber) async {
    _data(
      await dio.post(
        '/companies/${Uri.encodeComponent(companyId)}/invitations',
        data: {'phoneNumber': phoneNumber.trim(), 'role': 'MANAGER'},
      ),
    );
  }

  Future<Map<String, dynamic>> inquiry(String id) async => _data(
    await dio.get('/companies/booking-requests/${Uri.encodeComponent(id)}'),
  );
  Future<void> inquiryAction(
    String id,
    String action,
    Map<String, dynamic> body,
  ) async {
    _data(
      await dio.post(
        '/companies/booking-requests/${Uri.encodeComponent(id)}/$action',
        data: body,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> inquiryList([String? companyId]) async {
    final response = await dio.get(
      companyId == null
          ? '/companies/booking-requests/mine'
          : '/companies/${Uri.encodeComponent(companyId)}/orders',
    );
    if ((response.statusCode ?? 500) >= 400 ||
        response.data is! Map ||
        response.data['data'] is! List) {
      throw CompanyApiException(response.statusCode, 'INQUIRIES');
    }
    return companyObjectList(response.data['data']);
  }

  // ApiClient accepts 4xx/5xx responses: never turn an error into an empty park
  // or a successful registration.
  Map<String, dynamic> _data(Response<dynamic> response) {
    final body = response.data;
    if ((response.statusCode ?? 500) >= 400 || body is! Map) {
      final error = body is Map ? body['error'] : null;
      throw CompanyApiException(
        response.statusCode,
        error is Map
            ? '${error['code'] ?? ''}'
            : body is Map
            ? '${body['code'] ?? ''}'
            : '',
        error is Map && error['message'] is String
            ? error['message'] as String
            : null,
      );
    }
    final data = body['data'] ?? body;
    if (data is! Map) throw const CompanyApiException(null, 'INVALID_RESPONSE');
    return Map<String, dynamic>.from(data);
  }

  Future<CompanyContext> me() async =>
      CompanyContext.fromJson(_data(await dio.get('/companies/me')));
  Future<void> apply({required String name, required String bin}) async {
    _data(
      await dio.post(
        '/companies/requests',
        data: {'name': name.trim(), 'bin': bin.trim()},
      ),
    );
  }

  Future<void> acceptInvitation(String id) async {
    _data(
      await dio.post(
        '/companies/invitations/${Uri.encodeComponent(id)}/accept',
      ),
    );
  }

  Future<CompanyFleet> fleet(String companyId) async => CompanyFleet.fromJson(
    _data(await dio.get('/companies/${Uri.encodeComponent(companyId)}/fleet')),
  );
  Future<void> updateProfile(
    String id, {
    required String name,
    required String description,
  }) async {
    _data(
      await dio.patch(
        '/companies/${Uri.encodeComponent(id)}',
        data: {'name': name.trim(), 'description': description.trim()},
      ),
    );
  }

  Future<List<CompanyPhoto>> photos(String id) async {
    final entries = _data(await dio.get('/companies/$id/photos'));
    final result = <CompanyPhoto>[];
    for (final item in entries['photos'] as List) {
      final response = await dio.get<List<int>>(
        '/companies/$id/photos/${item['id']}',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw CompanyApiException(response.statusCode, 'PHOTO_UNAVAILABLE');
      }
      if (response.data != null) {
        result.add(
          CompanyPhoto(
            item['id'] as String,
            Uint8List.fromList(response.data!),
          ),
        );
      }
    }
    return result;
  }

  Future<void> removePhoto(String id, String photoId) async {
    _data(await dio.delete('/companies/$id/photos/$photoId'));
  }

  Future<void> addPhoto(String id, String path) async {
    _data(
      await dio.post(
        '/companies/$id/photos',
        data: FormData.fromMap({'logo': await MultipartFile.fromFile(path)}),
      ),
    );
  }

  Future<Uint8List?> logo(String id) async {
    final response = await dio.get<List<int>>(
      '/companies/${Uri.encodeComponent(id)}/logo',
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200 || response.data == null) {
      throw CompanyApiException(response.statusCode, 'LOGO_UNAVAILABLE');
    }
    return Uint8List.fromList(response.data!);
  }

  Future<void> uploadLogo(String id, String path) async {
    _data(
      await dio.post(
        '/companies/${Uri.encodeComponent(id)}/logo',
        data: FormData.fromMap({'logo': await MultipartFile.fromFile(path)}),
      ),
    );
  }

  Future<String> saveEquipment(
    String companyId, {
    CompanyFleetItem? item,
    String? equipmentId,
    required String name,
    required String model,
    String? plateNumber,
    required String categoryId,
    String? serviceCityId,
    required String ownerComment,
  }) async {
    final path = '/companies/${Uri.encodeComponent(companyId)}/fleet';
    final data = {
      'name': name.trim(),
      'model': model.trim(),
      if (plateNumber != null) 'plateNumber': plateNumber.trim(),
      'categoryId': categoryId,
      if (serviceCityId != null && serviceCityId.isNotEmpty)
        'serviceCityId': serviceCityId,
      'ownerComment': ownerComment.trim(),
    };
    final saved = _data(
      item == null && equipmentId == null
          ? await dio.post(path, data: data)
          : await dio.patch(
              '$path/${Uri.encodeComponent(equipmentId ?? item!.id)}',
              data: data,
            ),
    );
    return '${saved['id']}';
  }

  Future<void> setPrices(
    String companyId,
    String equipmentId,
    List<CompanyPrice> prices,
  ) async {
    _data(
      await dio.put(
        '/companies/${Uri.encodeComponent(companyId)}/fleet/${Uri.encodeComponent(equipmentId)}/prices',
        data: {
          'prices': [
            for (final price in prices)
              {
                'price': price.amount,
                'priceRate': price.rate,
                'label': price.label,
                'isStartingFrom': price.isStartingFrom,
              },
          ],
        },
      ),
    );
  }

  Future<List<PublicCompanySummary>> publicCompanies() async {
    final response = await dio.get('/companies/public');
    final body = response.data;
    if ((response.statusCode ?? 500) >= 400 || body is! Map) {
      throw CompanyApiException(response.statusCode, 'PUBLIC_COMPANIES');
    }
    final data = body['data'];
    if (data is! List) {
      throw const CompanyApiException(null, 'INVALID_RESPONSE');
    }
    return data
        .whereType<Map>()
        .map(
          (item) =>
              PublicCompanySummary.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<String> sendBookingRequest(
    String companyId, {
    required List<String> equipmentIds,
    required DateTime startsAt,
    String? comment,
    int? budget,
  }) async {
    final created = _data(
      await dio.post(
        '/companies/public/${Uri.encodeComponent(companyId)}/requests',
        data: {
          'equipmentIds': equipmentIds,
          'startsAt': startsAt.toUtc().toIso8601String(),
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
          'budget': ?budget,
        },
      ),
    );
    return '${created['id']}';
  }

  Future<PublicCompanyCard> publicCompany(String id) async =>
      PublicCompanyCard.fromJson(
        _data(await dio.get('/companies/public/${Uri.encodeComponent(id)}')),
      );

  Future<void> uploadEquipmentImage(
    String companyId,
    String equipmentId,
    String path,
  ) async {
    _data(
      await dio.post(
        '/companies/${Uri.encodeComponent(companyId)}/fleet/${Uri.encodeComponent(equipmentId)}/images',
        data: FormData.fromMap({
          'equipmentImage': await MultipartFile.fromFile(path),
        }),
      ),
    );
  }
}

final companyServiceProvider = Provider(
  (ref) => CompanyService(ref.watch(dioProvider)),
);

final companyContextProvider = FutureProvider.autoDispose<CompanyContext>((
  ref,
) async {
  final userId = ref.watch(authProvider.select((state) => state.currentUserId));
  if (userId == null) return const CompanyContext();
  return ref.watch(companyServiceProvider).me();
});

final companyFleetProvider = FutureProvider.autoDispose
    .family<CompanyFleet, String>((ref, id) async {
      final userId = ref.watch(
        authProvider.select((state) => state.currentUserId),
      );
      if (userId == null) throw const CompanyApiException(401, 'UNAUTHORIZED');
      return ref.watch(companyServiceProvider).fleet(id);
    });

final companySelectionProvider = StateProvider.family<Set<String>, String>((
  ref,
  companyId,
) {
  ref.watch(authProvider.select((state) => state.currentUserId));
  return <String>{};
});

final publicCompaniesProvider =
    FutureProvider.autoDispose<List<PublicCompanySummary>>((ref) async {
      return ref.watch(companyServiceProvider).publicCompanies();
    });

final publicCompanyProvider = FutureProvider.autoDispose
    .family<PublicCompanyCard, String>((ref, id) async {
      return ref.watch(companyServiceProvider).publicCompany(id);
    });

final companyLogoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, id) async {
      final userId = ref.watch(
        authProvider.select((state) => state.currentUserId),
      );
      if (userId == null) return null;
      return ref.watch(companyServiceProvider).logo(id);
    });

final companyBillingProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, id) {
      ref.watch(authProvider.select((state) => state.currentUserId));
      return ref.watch(companyServiceProvider).billing(id);
    });

final companyPhotosProvider = FutureProvider.autoDispose
    .family<List<CompanyPhoto>, String>((ref, id) {
      final userId = ref.watch(
        authProvider.select((state) => state.currentUserId),
      );
      if (userId == null) return Future.value(<CompanyPhoto>[]);
      return ref.watch(companyServiceProvider).photos(id);
    });

class CompanyPhoto {
  final String id;
  final Uint8List bytes;
  CompanyPhoto(this.id, this.bytes);
}
