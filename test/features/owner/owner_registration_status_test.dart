import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';

void main() {
  group('parseOwnerRegistrationStatus', () {
    test('maps OwnerProfileStatus from the API', () {
      expect(
        parseOwnerRegistrationStatus('APPROVED'),
        OwnerRegistrationStatus.approved,
      );
      expect(
        parseOwnerRegistrationStatus('INCOMPLETE'),
        OwnerRegistrationStatus.incomplete,
      );
      expect(
        parseOwnerRegistrationStatus('PENDING_REVIEW'),
        OwnerRegistrationStatus.pending,
      );
      expect(
        parseOwnerRegistrationStatus('REJECTED'),
        OwnerRegistrationStatus.rejected,
      );
      expect(
        parseOwnerRegistrationStatus('SUSPENDED'),
        OwnerRegistrationStatus.suspended,
      );
    });

    test('falls back to incomplete when status is missing', () {
      expect(
        parseOwnerRegistrationStatus(null),
        OwnerRegistrationStatus.incomplete,
      );
      expect(
        parseOwnerRegistrationStatus('UNKNOWN'),
        OwnerRegistrationStatus.incomplete,
      );
    });
  });

  group('shouldShowOwnerProfileStatusBanner', () {
    test('hides approved and incomplete — no documents or company signup', () {
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.approved),
        isFalse,
      );
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.incomplete),
        isFalse,
      );
      expect(shouldShowOwnerProfileStatusBanner(null), isFalse);
    });

    test('shows statuses that actually block the owner', () {
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.pending),
        isTrue,
      );
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.rejected),
        isTrue,
      );
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.suspended),
        isTrue,
      );
    });
  });
}
