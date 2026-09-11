import 'package:flutter/material.dart';

class ShakeOnTick extends StatefulWidget {
  final int tick;
  final Widget child;

  const ShakeOnTick({super.key, required this.tick, required this.child});

  @override
  State<ShakeOnTick> createState() => _ShakeOnTickState();
}

class _ShakeOnTickState extends State<ShakeOnTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  late final Animation<double> _shakeX;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shake, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant ShakeOnTick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick != oldWidget.tick && widget.tick > 0) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeX,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeX.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
