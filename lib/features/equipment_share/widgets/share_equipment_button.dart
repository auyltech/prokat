import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment_share/equipment_share_gate.dart';
import 'package:prokat/features/equipment_share/equipment_share_service.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ShareEquipmentButton extends ConsumerStatefulWidget {
  final Equipment equipment;
  final bool refreshOwnerDetails;
  final AppIconButtonVariant variant;

  const ShareEquipmentButton({
    super.key,
    required this.equipment,
    this.refreshOwnerDetails = false,
    this.variant = AppIconButtonVariant.soft,
  });

  @override
  ConsumerState<ShareEquipmentButton> createState() =>
      _ShareEquipmentButtonState();
}

class _ShareEquipmentButtonState extends ConsumerState<ShareEquipmentButton> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await EquipmentShareService.share(
        context: context,
        ref: ref,
        equipment: widget.equipment,
        refreshOwnerDetails: widget.refreshOwnerDetails,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!canShowShareButton(widget.equipment)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return AppIconButton(
      icon: LucideIcons.share2,
      tooltip: l10n.shareEquipment,
      semanticLabel: l10n.shareEquipment,
      variant: widget.variant,
      isLoading: _busy,
      onTap: () => unawaited(_share()),
    );
  }
}
