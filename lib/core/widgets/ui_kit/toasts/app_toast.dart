import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';

enum AppToastType { info, success, error }

/// Passive floating toast for non-interactive feedback (errors, status, success).
///
/// Renders in a root [Overlay] via [AppToastHost] so toasts appear above modal
/// routes (sheets, dialogs). Each [show] replaces the current toast. Visible
/// for 4 seconds unless dismissed by a downward swipe.
abstract final class AppToast {
  static const Duration _displayDuration = Duration(seconds: 4);

  /// Extra lift above the safe-area bottom edge (on top of [AppDimens.s16$base]).
  static const double _bottomLift = 80;

  static OverlayState? _overlay;
  static OverlayEntry? _entry;
  static Timer? _dismissTimer;
  static VoidCallback? _requestDismiss;

  /// Called by [AppToastHost]; do not invoke from feature code.
  static void _attachOverlay(OverlayState overlay) {
    _overlay = overlay;
  }

  /// Called by [AppToastHost] when the host is disposed.
  static void _detachOverlay(OverlayState overlay) {
    if (!identical(_overlay, overlay)) return;
    _clearActiveToast(removeEntry: true);
    _overlay = null;
  }

  static void _clearActiveToast({required bool removeEntry}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _requestDismiss = null;
    if (removeEntry) {
      _entry?.remove();
      _entry = null;
    }
  }

  static void show({
    required String message,
    AppToastType type = AppToastType.info,
    IconData? icon,
  }) {
    final overlay = _overlay;
    if (overlay == null || !overlay.mounted) return;

    _clearActiveToast(removeEntry: true);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _AppToastView(
          message: message,
          type: type,
          icon: icon,
          bottomLift: _bottomLift,
          onRegisterDismiss: (dismiss) {
            if (identical(_entry, entry)) {
              _requestDismiss = dismiss;
            }
          },
          onClosed: () {
            if (!identical(_entry, entry)) return;
            _clearActiveToast(removeEntry: true);
          },
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(_displayDuration, () {
      if (!identical(_entry, entry)) return;
      final dismiss = _requestDismiss;
      if (dismiss != null) {
        dismiss();
      } else {
        _clearActiveToast(removeEntry: true);
      }
    });
  }
}

/// Wraps the app under [MaterialApp.builder] so [AppToast] can paint above
/// navigator modals.
class AppToastHost extends StatefulWidget {
  const AppToastHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost> {
  late final OverlayEntry _appEntry = OverlayEntry(
    builder: (context) => widget.child,
  );

  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _register());
  }

  @override
  void didUpdateWidget(covariant AppToastHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _appEntry.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    final overlay = _overlayKey.currentState;
    if (overlay != null) {
      AppToast._detachOverlay(overlay);
    }
    super.dispose();
  }

  void _register() {
    final overlay = _overlayKey.currentState;
    if (overlay == null || !mounted) return;
    AppToast._attachOverlay(overlay);
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(key: _overlayKey, initialEntries: [_appEntry]);
  }
}

class _AppToastView extends StatefulWidget {
  const _AppToastView({
    required this.message,
    required this.type,
    required this.icon,
    required this.bottomLift,
    required this.onRegisterDismiss,
    required this.onClosed,
  });

  final String message;
  final AppToastType type;
  final IconData? icon;
  final double bottomLift;
  final void Function(VoidCallback dismiss) onRegisterDismiss;
  final VoidCallback onClosed;

  @override
  State<_AppToastView> createState() => _AppToastViewState();
}

class _AppToastViewState extends State<_AppToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDimens.defaultAnimationDuration,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onAnimationStatus);
    widget.onRegisterDismiss(_dismissAnimated);
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _closing && mounted) {
      widget.onClosed();
    }
  }

  void _dismissAnimated() {
    if (_closing) return;
    _closing = true;
    if (_controller.isDismissed) {
      widget.onClosed();
      return;
    }
    unawaited(
      _controller.reverse().then((_) {
        if (mounted) widget.onClosed();
      }),
    );
  }

  void _dismissFromSwipe() {
    if (_closing) return;
    _closing = true;
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final toastColors = colors.toast;
    final Color backgroundColor;
    final IconData icon;

    switch (widget.type) {
      case AppToastType.error:
        backgroundColor = toastColors.error;
        icon = widget.icon ?? Icons.error_outline;
      case AppToastType.success:
        backgroundColor = toastColors.success;
        icon = widget.icon ?? Icons.check_circle_outline;
      case AppToastType.info:
        backgroundColor = toastColors.info;
        icon = widget.icon ?? Icons.info_outline;
    }

    final contentColor = toastColors.content;

    final toast = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.s12$md),
        boxShadow: colors.dialogShadows,
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimens.s12$md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.s16$base,
            vertical: AppDimens.s12$md,
          ),
          child: Row(
            children: [
              Icon(icon, color: contentColor, size: AppDimens.s24$xl),
              const SizedBox(width: AppDimens.s12$md),
              Expanded(
                child: Text(
                  widget.message,
                  style: AppFonts.body16SemiBold(context)
                      .copyWith(color: contentColor, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.s16$base,
            AppDimens.s16$base,
            AppDimens.s16$base,
            AppDimens.s16$base + widget.bottomLift,
          ),
          child: SlideTransition(
            position: _slide,
            child: Dismissible(
              key: ValueKey<String>(widget.message),
              direction: DismissDirection.down,
              onDismissed: (_) => _dismissFromSwipe(),
              child: toast,
            ),
          ),
        ),
      ),
    );
  }
}
