import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_details_provider.dart';
import 'package:prokat/features/equipment_share/equipment_share_analytics.dart';
import 'package:prokat/features/equipment_share/equipment_share_gate.dart';
import 'package:prokat/features/equipment_share/equipment_share_message.dart';
import 'package:prokat/features/equipment_share/equipment_share_renderer.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class EquipmentShareService {
  static bool _inFlight = false;

  static Future<void> share({
    required BuildContext context,
    required WidgetRef ref,
    required Equipment equipment,
    bool refreshOwnerDetails = false,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    File? file;
    ui.Image? image;
    try {
      var current = equipment;
      if (refreshOwnerDetails) {
        current = await _refreshedOwnerEquipment(context, ref, equipment);
        if (!context.mounted) return;
      }

      final l10n = AppLocalizations.of(context)!;
      if (needsPublishAlert(current)) {
        await AppAlertBottomSheet.show(
          context,
          title: l10n.shareEquipmentTitle,
          description: l10n.shareEquipmentNeedPublish,
          primaryLabel: l10n.close,
        );
        return;
      }
      if (!isShareableNow(current)) return;

      final priceLine = sharePriceLine(current, l10n);
      if (priceLine == null) return;

      EquipmentShareAnalytics.shareStarted(current.id);
      image = await EquipmentShareRenderer.render(
        context: context,
        ref: ref,
        equipment: current,
        priceLine: priceLine,
        cta: l10n.shareEquipmentCta,
      );
      if (!context.mounted) return;

      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Share card PNG was empty.');
      }
      final directory = await getTemporaryDirectory();
      file = File(
        '${directory.path}/equipment-share-${current.id}-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!context.mounted) return;

      final origin = _shareOrigin(context);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: 'prokat.png')],
          text: equipmentShareMessage(
            l10n,
            name: current.name,
            priceLine: priceLine,
            url: Env.equipmentShareUrl(current.id),
          ),
          subject: current.name,
          sharePositionOrigin: origin,
        ),
      );
      EquipmentShareAnalytics.shareCompleted(current.id);
    } catch (_) {
      EquipmentShareAnalytics.shareFailed(equipment.id);
      if (context.mounted) {
        AppToast.show(
          message: AppLocalizations.of(context)!.somethingWentWrongTryAgain,
          type: AppToastType.error,
        );
      }
    } finally {
      image?.dispose();
      _inFlight = false;
      final pending = file;
      if (pending != null) {
        try {
          await pending.delete();
        } catch (_) {}
      }
    }
  }

  static Future<Equipment> _refreshedOwnerEquipment(
    BuildContext context,
    WidgetRef ref,
    Equipment equipment,
  ) async {
    try {
      await ref
          .read(ownerEquipmentDetailsProvider(equipment.id).notifier)
          .refresh();
    } catch (_) {}
    if (!context.mounted) return equipment;
    return ref.read(ownerEquipmentDetailsProvider(equipment.id)).valueOrNull ??
        equipment;
  }

  static Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
