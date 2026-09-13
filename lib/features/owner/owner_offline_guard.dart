import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
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
/// Going online from the dialog closes it and leaves the original tap unsent
/// so the owner can accept, bargain, or chat themselves.
Future<bool> ensureOwnerOnline(
  BuildContext context,
  Object ref, {
  required String message,
}) async {
  if (isOwnerAccountOnline(ref)) return true;
  if (!context.mounted) return false;

  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  final wentOnline = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _OwnerGoOnlineDialog(
        message: message,
        cancelLabel: l10n.cancel,
        becomeOnlineLabel: l10n.becomeOnline,
        backgroundColor: theme.colorScheme.surface,
        onBecomeOnline: () async {
          final preCheck = ownerGoOnlineBlockReason(ref);
          if (preCheck != OwnerGoOnlineBlockReason.none) {
            if (dialogContext.mounted) {
              AppSnackBar.show(
                message: ownerGoOnlineBlockMessage(
                  l10n: l10n,
                  reason: preCheck,
                ),
                isError: true,
              );
            }
            return false;
          }

          final ok = await requestOwnerGoOnline(ref);
          if (!dialogContext.mounted) return false;

          if (!ok) {
            AppSnackBar.show(
              message: ownerGoOnlineFailureMessage(
                ref: ref,
                l10n: l10n,
                preCheck: OwnerGoOnlineBlockReason.none,
              ),
              isError: true,
            );
            return false;
          }

          return true;
        },
      );
    },
  );

  if (wentOnline == true && context.mounted) {
    AppSnackBar.show(message: l10n.accountSwitchedToOnline, isSuccess: true);
  }

  return false;
}

const _onlineSwitchThumb = Color(0xFF0F5A56);
const _onlineSwitchTrack = Color(0xFF3D8B74);

class BecomeOnlineOutlinedButton extends StatelessWidget {
  const BecomeOnlineOutlinedButton({
    super.key,
    required this.label,
    required this.switchOn,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool switchOn;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch.adaptive(
                  value: switchOn,
                  activeThumbColor: _onlineSwitchThumb,
                  activeTrackColor: _onlineSwitchTrack,
                  onChanged: busy ? null : (_) => onPressed(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerGoOnlineDialog extends StatefulWidget {
  final String message;
  final String cancelLabel;
  final String becomeOnlineLabel;
  final Color backgroundColor;
  final Future<bool> Function() onBecomeOnline;

  const _OwnerGoOnlineDialog({
    required this.message,
    required this.cancelLabel,
    required this.becomeOnlineLabel,
    required this.backgroundColor,
    required this.onBecomeOnline,
  });

  @override
  State<_OwnerGoOnlineDialog> createState() => _OwnerGoOnlineDialogState();
}

class _OwnerGoOnlineDialogState extends State<_OwnerGoOnlineDialog> {
  bool _loading = false;
  bool _switchOn = false;

  Future<void> _onBecomeOnline() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _switchOn = true;
    });

    final ok = await widget.onBecomeOnline();
    if (!mounted) return;

    if (ok) {
      await Future<void>.delayed(const Duration(milliseconds: 380));
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _loading = false;
      _switchOn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outline.withValues(alpha: 0.7);

    return AlertDialog(
      backgroundColor: widget.backgroundColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BecomeOnlineOutlinedButton(
                  label: widget.becomeOnlineLabel,
                  switchOn: _switchOn,
                  busy: _loading,
                  onPressed: _onBecomeOnline,
                ),
              ),
            ],
          ),
        ],
      ),
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
