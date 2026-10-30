import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/features/notifications/models/app_notification.dart';

/// One foreground surface for socket and FCM, independent of OS push permission.
class ForegroundNotificationPresenter {
  ForegroundNotificationPresenter({
    required this.overlay,
    required this.locale,
    required this.onTap,
    required this.accepts,
    required this.isRead,
  });

  final OverlayState? Function() overlay;
  final String Function() locale;
  final void Function(AppNotification) onTap;
  final bool Function(AppNotification) accepts;
  final bool Function(String) isRead;
  final Map<String, DateTime> _shown = {};
  OverlayEntry? _entry;
  Timer? _timer;

  /// True also for duplicates: the caller must not produce a second OS banner.
  bool present(AppNotification notification) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return false;
    if (!accepts(notification) ||
        notification.isRead ||
        isRead(notification.id)) {
      return true;
    }
    final now = DateTime.now();
    _shown.removeWhere(
      (_, at) => now.difference(at) > const Duration(minutes: 10),
    );
    final id = notification.id.trim();
    if (id.isNotEmpty && _shown.containsKey(id)) return true;
    final target = overlay();
    if (target == null) return false;
    dismiss();
    if (id.isNotEmpty) _shown[id] = now;
    _entry = OverlayEntry(
      builder: (context) {
        final palette = ProkatFlowPalette.of(context);
        return Positioned(
          top: 0,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -20, end: 0),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              builder: (context, offset, child) =>
                  Transform.translate(offset: Offset(0, offset), child: child),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: palette.surface,
                  elevation: 8,
                  shadowColor: palette.title.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: palette.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      dismiss();
                      onTap(notification);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: palette.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.bellRing,
                              size: 21,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  notification.localizedTitle(locale()),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: palette.title,
                                  ),
                                ),
                                if (notification
                                    .localizedBody(locale())
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.localizedBody(locale()),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      color: palette.secondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .closeButtonTooltip,
                            onPressed: dismiss,
                            icon: Icon(
                              LucideIcons.x,
                              size: 18,
                              color: palette.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    target.insert(_entry!);
    _timer = Timer(const Duration(seconds: 6), dismiss);
    return true;
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  void reset() {
    dismiss();
    _shown.clear();
  }
}
