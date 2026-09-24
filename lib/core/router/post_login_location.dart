import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';

/// Guest login button that is still waiting for OTP (`from` query on `/login`).
final postLoginFromProvider = StateProvider<String?>((ref) => null);

/// Where to go after a successful OTP while still on `/login`.
///
/// Guest footer "Получать заказы" passes [AppRoutes.becomeOwner]:
/// registered owners open the owner profile; everyone else gets the
/// application form.
///
/// Guest "Нанять технику" passes [AppRoutes.clientProfile] and always
/// opens the client profile.
String resolvePostLoginLocation({
  required String? from,
  required bool ownerModeActive,
  required bool accountIsOwner,
}) {
  if (from != null && from.startsWith('/e/')) {
    return from;
  }

  if (from == AppRoutes.becomeOwner) {
    return accountIsOwner ? AppRoutes.ownerProfile : AppRoutes.becomeOwner;
  }

  if (from == AppRoutes.clientProfile || from == null || from.isEmpty) {
    return AppRoutes.clientProfile;
  }

  if (from.startsWith(AppRoutes.clientMain) ||
      from.startsWith(AppRoutes.ownerMain)) {
    if (from.startsWith(AppRoutes.ownerMain) &&
        !(ownerModeActive || accountIsOwner)) {
      return AppRoutes.searchList;
    }
    return from;
  }

  return ownerModeActive ? AppRoutes.ownerProfile : AppRoutes.clientProfile;
}
