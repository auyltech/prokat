import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';

/// Grows and shrinks [child] vertically when [visible] changes.
class AppReveal extends StatefulWidget {
  final bool visible;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AppReveal({
    super.key,
    required this.visible,
    required this.child,
    this.duration = AppDimens.defaultAnimationDuration,
    this.curve = Curves.easeInOut,
  });

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.visible ? 1 : 0,
  );

  late final Animation<double> _factor = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  @override
  void didUpdateWidget(covariant AppReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _factor,
        builder: (context, child) {
          final hidden = _factor.value == 0;
          return ExcludeSemantics(
            excluding: hidden,
            child: IgnorePointer(
              ignoring: hidden,
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _factor.value,
                child: child,
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
