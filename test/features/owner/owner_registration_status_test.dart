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
        parseOwnerRegistrationStatus('CHANGES_PENDING_REVIEW'),
        OwnerRegistrationStatus.changesPending,
      );
      expect(
        parseOwnerRegistrationStatus('REJECTED'),
        OwnerRegistrationStatus.rejected,
      );
      expect(
        parseOwnerRegistrationStatus('CHANGES_REJECTED'),
        OwnerRegistrationStatus.changesRejected,
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

    test('shows moderation and correction statuses', () {
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.pending),
        isTrue,
      );
      expect(
        shouldShowOwnerProfileStatusBanner(
          OwnerRegistrationStatus.changesPending,
        ),
        isTrue,
      );
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.rejected),
        isTrue,
      );
      expect(
        shouldShowOwnerProfileStatusBanner(
          OwnerRegistrationStatus.changesRejected,
        ),
        isTrue,
      );
      expect(
        shouldShowOwnerProfileStatusBanner(OwnerRegistrationStatus.suspended),
        isTrue,
      );
    });
  });

  group('isOwnerBusinessProfileLocked', () {
    test('locks pending and changesPending review', () {
      expect(
        isOwnerBusinessProfileLocked(OwnerRegistrationStatus.pending),
        isTrue,
      );
      expect(
        isOwnerBusinessProfileLocked(OwnerRegistrationStatus.changesPending),
        isTrue,
      );
      expect(
        isOwnerBusinessProfileLocked(OwnerRegistrationStatus.approved),
        isFalse,
      );
      expect(
        isOwnerBusinessProfileLocked(OwnerRegistrationStatus.rejected),
        isFalse,
      );
      expect(
        isOwnerBusinessProfileLocked(OwnerRegistrationStatus.changesRejected),
        isFalse,
      );
      expect(
        isOwnerBusinessProfileLocked(OwnerRegistrationStatus.incomplete),
        isFalse,
      );
      expect(
        isOwnerBusinessProfileLocked(OwnerRegistrationStatus.suspended),
        isFalse,
      );
      expect(isOwnerBusinessProfileLocked(null), isFalse);
    });
  });
  group('effectiveOwnerBusinessStatus', () {
    test('maps legacy pending/rejected to CHANGES_* for owner cycle', () {
      expect(
        effectiveOwnerBusinessStatus(
          status: OwnerRegistrationStatus.pending,
          ownerCycle: true,
        ),
        OwnerRegistrationStatus.changesPending,
      );
      expect(
        effectiveOwnerBusinessStatus(
          status: OwnerRegistrationStatus.rejected,
          ownerCycle: true,
        ),
        OwnerRegistrationStatus.changesRejected,
      );
      expect(
        effectiveOwnerBusinessStatus(
          status: OwnerRegistrationStatus.rejected,
          isVerified: false,
        ),
        OwnerRegistrationStatus.rejected,
      );
      expect(
        effectiveOwnerBusinessStatus(
          status: OwnerRegistrationStatus.rejected,
          isVerified: true,
        ),
        OwnerRegistrationStatus.changesRejected,
      );
    });
  });
}
