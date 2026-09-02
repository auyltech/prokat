import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';

String ownerProfileComparableText(String? value) => (value ?? '').trim();

String ownerProfileComparablePhone(String? value) =>
    normalizeKzPhone(value) ?? ownerProfileComparableText(value);

bool ownerBusinessProfileHasChanges({
  required OwnerProfileModel current,
  required String firstName,
  required String lastName,
  required String? phoneNumber,
  required String? city,
  required String serviceDescription,
}) {
  return ownerProfileComparableText(current.firstName) !=
          ownerProfileComparableText(firstName) ||
      ownerProfileComparableText(current.lastName) !=
          ownerProfileComparableText(lastName) ||
      ownerProfileComparablePhone(current.phoneNumber) !=
          ownerProfileComparablePhone(phoneNumber) ||
      ownerProfileComparableText(current.city) !=
          ownerProfileComparableText(city) ||
      ownerProfileComparableText(current.serviceDescription) !=
          ownerProfileComparableText(serviceDescription);
}
