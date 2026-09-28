import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/post_login_location.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';

void main() {
  test('startupLandingLocation maps ready states', () {
    expect(startupLandingLocation(AppStartupRouteState.guest), AppRoutes.main);
    expect(
      startupLandingLocation(AppStartupRouteState.client),
      AppRoutes.searchList,
    );
    expect(
      startupLandingLocation(AppStartupRouteState.owner),
      AppRoutes.ownerEquipment,
    );
    expect(startupLandingLocation(AppStartupRouteState.loading), isNull);
    expect(startupLandingLocation(AppStartupRouteState.otp), isNull);
    expect(startupLandingLocation(AppStartupRouteState.error), isNull);
  });
}
