import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';

/// Opts a screen into the new visual presets while reusing existing controls.
class ProkatFlowScope extends InheritedWidget {
  final ProkatFlowPalette palette;
  final bool enabled;

  const ProkatFlowScope({
    super.key,
    required this.palette,
    this.enabled = true,
    required super.child,
  });

  static ProkatFlowPalette? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProkatFlowScope>();
    return scope?.enabled == true ? scope!.palette : null;
  }

  /// Keep the caller's appearance when an overlay uses the root navigator.
  static Widget capture(BuildContext context, Widget child) {
    final palette = maybeOf(context);
    return InheritedTheme.captureAll(
      context,
      palette == null ? child : ProkatFlowScope(palette: palette, child: child),
    );
  }

  @override
  bool updateShouldNotify(ProkatFlowScope oldWidget) =>
      palette != oldWidget.palette || enabled != oldWidget.enabled;
}

/// Applies the shared appearance to a standalone route without changing it.
class ProkatFlowPage extends StatelessWidget {
  const ProkatFlowPage({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    return ProkatFlowScope(
      palette: palette,
      child: Theme(
        data: palette.themeFor(Theme.of(context)),
        child: Builder(builder: builder),
      ),
    );
  }
}
