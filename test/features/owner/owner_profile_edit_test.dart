import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/owner/models/owner_profile_edit.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/models/owner_status.dart';

OwnerProfileModel _profile({
  String? firstName = 'Нурлан',
  String? lastName = 'Бекенов',
  String? phoneNumber = '+77053333333',
  String? city = 'almaty',
  String? serviceDescription = 'Экскаваторы',
}) {
  return OwnerProfileModel(
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    city: city,
    serviceDescription: serviceDescription,
    status: OwnerRegistrationStatus.approved,
    onlineStatus: OwnerStatus.offline,
  );
}

void main() {
  test('masked phone and same fields are not a profile edit', () {
    expect(
      ownerBusinessProfileHasChanges(
        current: _profile(),
        firstName: 'Нурлан',
        lastName: 'Бекенов',
        phoneNumber: '+7(705)333-33-33',
        city: 'almaty',
        serviceDescription: 'Экскаваторы',
      ),
      isFalse,
    );
  });

  test('any visible business-profile field change is a profile edit', () {
    expect(
      ownerBusinessProfileHasChanges(
        current: _profile(),
        firstName: 'Нурлан',
        lastName: 'Бекенов',
        phoneNumber: '+77053333333',
        city: 'astana',
        serviceDescription: 'Экскаваторы',
      ),
      isTrue,
    );
  });
}
