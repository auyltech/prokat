import 'package:flutter/widgets.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';

/// Opts a screen into the new visual presets while reusing existing controls.
class ProkatFlowScope extends InheritedWidget {
  final ProkatFlowPalette palette;

  const ProkatFlowScope({
    super.key,
    required this.palette,
    required super.child,
  });

  static ProkatFlowPalette? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProkatFlowScope>()?.palette;

  @override
  bool updateShouldNotify(ProkatFlowScope oldWidget) =>
      palette != oldWidget.palette;
}
