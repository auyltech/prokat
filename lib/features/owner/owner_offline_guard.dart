import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/offers/offer_error_message.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

const bookingOwnerOfflineCode = 'BOOKING_OWNER_OFFLINE';

OwnerStatus? ownerOnlineStatusOf(Object ref) {
  if (ref is WidgetRef) {
    return ref.read(ownerProfileProvider).valueOrNull?.onlineStatus;
  }
  if (ref is Ref) {
    return ref.read(ownerProfileProvider).valueOrNull?.onlineStatus;
  }
  return null;
}

bool isOwnerAccountOnline(Object ref) {
  return ownerOnlineStatusOf(ref) == OwnerStatus.online;
}

/// Shows the offline warning and returns true when the owner cannot accept.
///
/// If the profile has not loaded yet, this does not block locally — the API
/// still rejects accept/offer while offline.
bool warnIfOwnerOffline(BuildContext context, Object ref) {
  final status = ownerOnlineStatusOf(ref);
  if (status == null || status == OwnerStatus.online) return false;
  AppSnackBar.show(
    message: AppLocalizations.of(context)!.ownerOfflineMustBeOnlineToAccept,
    isError: true,
  );
  return true;
}

String ownerOfflineActionErrorMessage({
  required AppLocalizations l10n,
  String? errorCode,
  String? fallback,
}) {
  if (errorCode == bookingOwnerOfflineCode ||
      errorCode == offerCreateOwnerOfflineCode) {
    return l10n.ownerOfflineMustBeOnlineToAccept;
  }
  final trimmed = fallback?.trim() ?? '';
  return trimmed.isEmpty ? l10n.actionFailed : trimmed;
}
