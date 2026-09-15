import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/widgets/ui_kit/toasts/app_toast.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_outlined_button.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_bottom_sheet.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/offers/offer_error_message.dart';
import 'package:prokat/features/owner/models/owner_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/state/owner_registration_service.dart';
import 'package:prokat/l10n/app_localizations.dart';

const bookingOwnerOfflineCode = 'BOOKING_OWNER_OFFLINE';

enum OwnerGoOnlineBlockReason { none, zeroBalance, noOnlineEquipment }

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

T _read<T>(Object ref, ProviderListenable<T> provider) {
  if (ref is WidgetRef) return ref.read(provider);
  if (ref is Ref) return ref.read(provider);
  throw ArgumentError('Unsupported ref type: ${ref.runtimeType}');
}

OwnerGoOnlineBlockReason ownerGoOnlineBlockReason(Object ref) {
  final billing = _read(ref, billingProvider);
  if (billing.isOutOfPaidMinutes) {
    return OwnerGoOnlineBlockReason.zeroBalance;
  }

  final onlineEquipmentCount = _read(
    ref,
    ownerEquipmentProvider.notifier,
  ).onlineEquipmentCount;
  if (onlineEquipmentCount == 0) {
    return OwnerGoOnlineBlockReason.noOnlineEquipment;
  }

  return OwnerGoOnlineBlockReason.none;
}

String ownerGoOnlineBlockMessage({
  required AppLocalizations l10n,
  required OwnerGoOnlineBlockReason reason,
}) {
  switch (reason) {
    case OwnerGoOnlineBlockReason.zeroBalance:
      return l10n.cannotGoOnlineWithZeroBalance;
    case OwnerGoOnlineBlockReason.noOnlineEquipment:
      return l10n.cannotGoOnlineWithoutOnlineEquipment;
    case OwnerGoOnlineBlockReason.none:
      return l10n.failedToggleStatus;
  }
}

/// Client pre-check + PATCH ONLINE. Does not wait for catalog:visibility.
Future<bool> requestOwnerGoOnline(Object ref) async {
  final block = ownerGoOnlineBlockReason(ref);
  if (block != OwnerGoOnlineBlockReason.none) {
    return false;
  }

  return _read(
    ref,
    ownerRegistrationMutationProvider.notifier,
  ).updateOwnerStatus(ownerStatus: OwnerStatus.online);
}

String ownerGoOnlineFailureMessage({
  required Object ref,
  required AppLocalizations l10n,
  required OwnerGoOnlineBlockReason preCheck,
}) {
  if (preCheck != OwnerGoOnlineBlockReason.none) {
    return ownerGoOnlineBlockMessage(l10n: l10n, reason: preCheck);
  }

  final errorCode = _read(ref, ownerRegistrationMutationProvider).errorCode;
  if (errorCode == ownerOnlineZeroBalanceCode) {
    return l10n.cannotGoOnlineWithZeroBalance;
  }
  if (errorCode == ownerOnlineNoEquipmentCode) {
    return l10n.cannotGoOnlineWithoutOnlineEquipment;
  }
  return l10n.failedToggleStatus;
}

/// Local offline action gate. Returns true only if the owner is already online.
/// Going online from the sheet closes it and leaves the original tap unsent
/// so the owner can accept, bargain, or chat themselves.
Future<bool> ensureOwnerOnline(
  BuildContext context,
  Object ref, {
  required String message,
}) async {
  if (isOwnerAccountOnline(ref)) return true;
  if (!context.mounted) return false;

  final l10n = AppLocalizations.of(context)!;

  await AppBottomSheet.show<bool>(
    context,
    title: l10n.becomeOnline,
    contentBuilder: (sheetContext) {
      return _OwnerGoOnlineSheetContent(
        message: message,
        cancelLabel: l10n.cancel,
        becomeOnlineLabel: l10n.becomeOnline,
        onBecomeOnline: () async {
          final preCheck = ownerGoOnlineBlockReason(ref);
          if (preCheck != OwnerGoOnlineBlockReason.none) {
            if (sheetContext.mounted) {
              AppToast.show(
                message: ownerGoOnlineBlockMessage(
                  l10n: l10n,
                  reason: preCheck,
                ),
                type: AppToastType.error,
              );
            }
            return false;
          }

          final ok = await requestOwnerGoOnline(ref);
          if (!sheetContext.mounted) return false;

          if (!ok) {
            AppToast.show(
              message: ownerGoOnlineFailureMessage(
                ref: ref,
                l10n: l10n,
                preCheck: OwnerGoOnlineBlockReason.none,
              ),
              type: AppToastType.error,
            );
            return false;
          }

          return true;
        },
      );
    },
  );

  // Success toast comes from updateOwnerStatus. Original tap is not resumed.
  return false;
}

class BecomeOnlineOutlinedButton extends StatelessWidget {
  const BecomeOnlineOutlinedButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withValues(alpha: 0.7);

    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _OwnerGoOnlineSheetContent extends StatefulWidget {
  final String message;
  final String cancelLabel;
  final String becomeOnlineLabel;
  final Future<bool> Function() onBecomeOnline;

  const _OwnerGoOnlineSheetContent({
    required this.message,
    required this.cancelLabel,
    required this.becomeOnlineLabel,
    required this.onBecomeOnline,
  });

  @override
  State<_OwnerGoOnlineSheetContent> createState() =>
      _OwnerGoOnlineSheetContentState();
}

class _OwnerGoOnlineSheetContentState
    extends State<_OwnerGoOnlineSheetContent> {
  bool _loading = false;

  Future<void> _onBecomeOnline() async {
    if (_loading) return;
    setState(() => _loading = true);

    final ok = await widget.onBecomeOnline();
    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimens.s24$xl,
      children: [
        Text(
          widget.message,
          textAlign: TextAlign.center,
          style: AppFonts.body16(context),
        ),
        Row(
          spacing: AppDimens.s12$md,
          children: [
            Expanded(
              child: AppOutlinedButton(
                title: widget.cancelLabel,
                onTap: _loading ? null : () => Navigator.of(context).pop(false),
              ),
            ),
            Expanded(
              child: AppElevatedButton(
                title: widget.becomeOnlineLabel,
                isLoading: _loading,
                onTap: _loading ? null : _onBecomeOnline,
              ),
            ),
          ],
        ),
      ],
    );
  }
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
