import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/equipment/equipment_create_error_message.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/equipment/providers/equipment_mutation_provider.dart';
import 'package:prokat/features/equipment/state/equipment_service.dart';
import 'package:prokat/l10n/app_localizations.dart';

class _ApiClient implements ApiClient {
  _ApiClient(this.dio);
  @override
  Dio dio;
}

void main() {
  for (final group in ['MACHINERY', 'EQUIPMENT']) {
    for (final locale in ['ru', 'kk', 'en']) {
      test('$group quota is localized in $locale with the server maximum', () {
        final l10n = lookupAppLocalizations(Locale(locale));
        final message = equipmentCreateErrorMessage(
          l10n: l10n,
          errorCode: equipmentCreateLimitCode,
          details: {'maximum': 500, 'catalogGroup': group},
          selectedGroup: group == 'EQUIPMENT' ? 'MACHINERY' : 'EQUIPMENT',
        );
        expect(
          message,
          group == 'EQUIPMENT'
              ? l10n.equipmentQuotaReached(500)
              : l10n.machineryQuotaReached(500),
        );
        expect(message, contains('500'));
      });
    }
  }
  test('legacy maximum-only payload uses the selected category group', () {
    final l10n = lookupAppLocalizations(const Locale('ru'));
    expect(
      equipmentCreateErrorMessage(
        l10n: l10n,
        errorCode: equipmentCreateLimitCode,
        details: {'maximum': 100},
        selectedGroup: 'EQUIPMENT',
      ),
      l10n.equipmentQuotaReached(100),
    );
    for (final details in [
      null,
      {},
      {'maximum': -1},
      {'maximum': '100'},
      {'maximum': 1.5},
    ]) {
      expect(
        equipmentCreateErrorMessage(
          l10n: l10n,
          errorCode: equipmentCreateLimitCode,
          details: details,
        ),
        l10n.couldNotAddEquipment,
      );
    }
    expect(
      equipmentCreateErrorMessage(
        l10n: l10n,
        errorCode: equipmentCreateLimitCode,
        details: {'maximum': 0, 'catalogGroup': 'MACHINERY'},
      ),
      l10n.machineryQuotaReached(0),
    );
    expect(
      equipmentCreateErrorMessage(l10n: l10n, errorCode: 'OTHER'),
      l10n.couldNotAddEquipment,
    );
  });
  for (final companyId in [null, 'company-1']) {
    test(
      '409 preserves quota through service and notifier, company=$companyId',
      () async {
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              expect(
                options.path,
                companyId == null
                    ? '/equipment'
                    : '/company-profile/company-1/equipment',
              );
              handler.reject(
                DioException.badResponse(
                  statusCode: 409,
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 409,
                    data: {
                      'success': false,
                      'error': {
                        'code': equipmentCreateLimitCode,
                        'message': 'You have reached maximum allowed equipment',
                        'details': {
                          'maximum': 300,
                          'catalogGroup': 'EQUIPMENT',
                        },
                      },
                    },
                  ),
                ),
              );
            },
          ),
        );
        final service = EquipmentService(_ApiClient(dio), companyId: companyId);
        final response = await service.createEquipment({'name': 'Lawnmower'});
        expect(response.statusCode, 409);
        expect(response.errorCode, equipmentCreateLimitCode);
        expect(response.errorDetails?['maximum'], 300);
        final container = ProviderContainer(
          overrides: [equipmentServiceProvider.overrideWithValue(service)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(equipmentMutationProvider.notifier);
        expect(await notifier.createEquipment({'name': 'Lawnmower'}), isFalse);
        final error = notifier.getActionError('equipment:create');
        expect(error?.code, equipmentCreateLimitCode);
        expect(error?.originalError['maximum'], 300);
        final l10n = lookupAppLocalizations(const Locale('ru'));
        expect(
          equipmentCreateErrorMessage(
            l10n: l10n,
            errorCode: error?.code,
            details: error?.originalError,
          ),
          l10n.equipmentQuotaReached(300),
        );
      },
    );
  }
  test('successful creation retains its id and request payload', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.data['categoryId'], 'lawnmower-category');
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {'id': 'new-equipment'},
                'message': 'Equipment created',
              },
            ),
          );
        },
      ),
    );
    final service = EquipmentService(_ApiClient(dio));
    expect(
      (await service.createEquipment({
        'name': 'Lawnmower',
        'categoryId': 'lawnmower-category',
      })).success,
      isTrue,
    );
    expect(service.lastCreatedEquipmentId, 'new-equipment');
  });
}
