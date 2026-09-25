import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/post_login_location.dart';

void main() {
  group('resolvePostLoginLocation', () {
    test('Receive orders opens owner profile for a registered owner', () {
      expect(
        resolvePostLoginLocation(
          from: AppRoutes.becomeOwner,
          ownerModeActive: false,
          accountIsOwner: true,
        ),
        AppRoutes.ownerProfile,
      );
    });

    test(
      'Receive orders opens the application when the account is not owner',
      () {
        expect(
          resolvePostLoginLocation(
            from: AppRoutes.becomeOwner,
            ownerModeActive: true,
            accountIsOwner: false,
          ),
          AppRoutes.becomeOwner,
        );
      },
    );

    test('Hire equipment always opens the client profile', () {
      expect(
        resolvePostLoginLocation(
          from: AppRoutes.clientProfile,
          ownerModeActive: true,
          accountIsOwner: true,
        ),
        AppRoutes.clientProfile,
      );
      expect(
        resolvePostLoginLocation(
          from: null,
          ownerModeActive: true,
          accountIsOwner: true,
        ),
        AppRoutes.clientProfile,
      );
    });

    test('a share link returns to the guest equipment card', () {
      const from = '/e/eq-1';
      expect(
        resolvePostLoginLocation(
          from: from,
          ownerModeActive: false,
          accountIsOwner: false,
        ),
        from,
      );
      expect(
        resolvePostLoginLocation(
          from: from,
          ownerModeActive: true,
          accountIsOwner: true,
        ),
        from,
      );
    });
  });
}
