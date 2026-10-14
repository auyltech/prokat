import 'package:flutter/widgets.dart';
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

  @override
  bool updateShouldNotify(ProkatFlowScope oldWidget) =>
      palette != oldWidget.palette || enabled != oldWidget.enabled;
}
