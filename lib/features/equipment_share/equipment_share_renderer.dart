import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/media/media_image_provider.dart';
import 'package:prokat/core/theme/app_images.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment_share/equipment_share_card.dart';
import 'package:prokat/features/equipment_share/equipment_share_message.dart';

class EquipmentShareRenderer {
  static const _coverTimeout = Duration(seconds: 8);

  static Future<ui.Image> render({
    required BuildContext context,
    required WidgetRef ref,
    required Equipment equipment,
    required String priceLine,
    required String cta,
  }) async {
    final cover = await _precacheCover(context, ref, equipment.primaryImageUrl);
    if (!context.mounted) {
      throw StateError('Share card context was unmounted.');
    }
    await _precacheLogo(context);
    if (!context.mounted) {
      throw StateError('Share card context was unmounted.');
    }

    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          left: -10000,
          top: 0,
          child: IgnorePointer(
            child: MediaQuery(
              data: MediaQuery.of(overlayContext)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: RepaintBoundary(
                key: boundaryKey,
                child: EquipmentShareCard(
                  name: equipment.name,
                  description: shareDescriptionOf(equipment),
                  priceLine: priceLine,
                  cta: cta,
                  cover: cover,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Share card was not painted.');
      }
      if (boundary.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
      }
      final painted =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (painted == null) {
        throw StateError('Share card was not painted.');
      }
      return await painted.toImage(pixelRatio: 1);
    } finally {
      entry.remove();
    }
  }

  static Future<ImageProvider<Object>?> _precacheCover(
    BuildContext context,
    WidgetRef ref,
    String? rawUrl,
  ) async {
    final provider = mediaImageProvider(ref, rawUrl);
    if (provider == null) return null;
    try {
      await precacheImage(provider, context).timeout(_coverTimeout);
      return provider;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _precacheLogo(BuildContext context) async {
    try {
      await precacheImage(AssetImage(AppImages.appLogo.iconKey), context);
    } catch (_) {}
  }
}
