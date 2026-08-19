import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/api/api_client.dart';
import 'package:prokat/features/auth/providers/authenticated_session_scope.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/state/client_profile_service.dart';

class _TestApiClient implements ApiClient {
  _TestApiClient(this.dio);

  @override
  Dio dio;
}

void main() {
  test(
    'client and owner profiles remain independent for an owner account',
    () async {
      final paths = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            final data = options.path == '/user/profile'
                ? {'firstName': 'Client side', 'role': 'owner'}
                : {
                    'id': 'owner-1',
                    'firstName': 'Owner side',
                    'onlineStatus': 'ONLINE',
                  };
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'data': data},
              ),
            );
          },
        ),
      );
      final apiClient = _TestApiClient(dio);
      final container = ProviderContainer(
        overrides: [
          authenticatedSessionScopeKeyProvider.overrideWithValue(
            const AuthenticatedSessionScopeKey.forUser('test-user'),
          ),
          clientProfileServiceProvider.overrideWithValue(
            ClientProfileService(apiClient),
          ),
          ownerRegistrationServiceProvider.overrideWithValue(
            OwnerRegistrationService(apiClient),
          ),
        ],
      );
      addTearDown(container.dispose);

      final client = await container.read(clientProfileProvider.future);
      final owner = await container.read(ownerProfileProvider.future);

      expect(client?.firstName, 'Client side');
      expect(owner?.firstName, 'Owner side');
      expect(paths, containsAll(['/user/profile', '/owner/profile']));
    },
  );
}
