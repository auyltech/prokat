import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/owner/state/owner_registration_dependencies.dart'
    as dependencies;
import 'package:prokat/features/owner/state/owner_registration_provider.dart'
    as providers;

void main() {
  test('ownerRegistrationServiceProvider has a single provider identity', () {
    expect(
      identical(
        dependencies.ownerRegistrationServiceProvider,
        providers.ownerRegistrationServiceProvider,
      ),
      isTrue,
    );
  });
}
