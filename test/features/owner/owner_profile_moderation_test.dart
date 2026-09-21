import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_profile_pending_change.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';

void main() {
  group('OwnerProfileModel.withPendingDraftApplied', () {
    test('overlays proposed pendingChanges.to onto live fields', () {
      final profile = OwnerProfileModel(
        firstName: 'Live',
        lastName: 'Owner',
        phoneNumber: '+77001112233',
        city: 'almaty',
        serviceDescription: 'Old desc',
        status: OwnerRegistrationStatus.changesRejected,
        onlineStatus: OwnerStatus.offline,
        pendingChanges: const [
          OwnerProfilePendingChange(
            field: 'firstName',
            from: 'Live',
            to: 'Proposed',
          ),
          OwnerProfilePendingChange(
            field: 'serviceDescription',
            from: 'Old desc',
            to: 'New desc',
          ),
        ],
      );

      final draft = profile.withPendingDraftApplied();
      expect(draft.firstName, 'Proposed');
      expect(draft.lastName, 'Owner');
      expect(draft.serviceDescription, 'New desc');
      expect(draft.city, 'almaty');
    });
  });

  group('OwnerProfileModel.fromJson', () {
    test('parses correction deadline and overdue flag', () {
      final profile = OwnerProfileModel.fromJson({
        'firstName': 'A',
        'status': 'CHANGES_REJECTED',
        'onlineStatus': 'OFFLINE',
        'correctionDeadlineAt': '2026-09-28T18:59:59.999Z',
        'isCorrectionOverdue': true,
        'pendingChanges': [
          {'field': 'city', 'from': 'almaty', 'to': 'astana'},
        ],
      });

      expect(profile.status, OwnerRegistrationStatus.changesRejected);
      expect(profile.isCorrectionOverdue, isTrue);
      expect(profile.correctionDeadlineAt, isNotNull);
      expect(profile.pendingChanges, hasLength(1));
      expect(profile.pendingChanges.first.to, 'astana');
    });
  });

  group('RegistrationRequestModel.kind', () {
    test('defaults to becomeOwner and parses PROFILE_UPDATE', () {
      expect(
        RegistrationRequestModel.fromJson({'status': 'CREATED'}).kind,
        BecomeOwnerRequestKind.becomeOwner,
      );
      expect(
        RegistrationRequestModel.fromJson({
          'status': 'CREATED',
          'kind': 'PROFILE_UPDATE',
        }).isBecomeOwner,
        isFalse,
      );
    });
  });
}
