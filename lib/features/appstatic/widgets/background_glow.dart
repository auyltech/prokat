import 'package:flutter/material.dart';

class BackgroundGlow extends StatelessWidget {
  final Color color;
  final double size;

  const BackgroundGlow({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Animates a multiplier from 0.85x size to 1.15x size
      tween: Tween<double>(begin: 0.85, end: 1.15),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOut,
      // The builder loops the animation backward and forward automatically
      onEnd: () {},
      builder: (context, scale, child) {
        // We use a key or state trick for continuous looping,
        // but for a true infinite loop without boilerplate, we wrap it in an implicitly looping widget:
        return _PulseWrapper(color: color, baseSize: size);
      },
    );
  }
}

// Helper widget to handle the clean continuous loop
class _PulseWrapper extends StatefulWidget {
  final Color color;
  final double baseSize;

  const _PulseWrapper({required this.color, required this.baseSize});

  @override
  State<_PulseWrapper> createState() => _PulseWrapperState();
}

class _PulseWrapperState extends State<_PulseWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true); // This creates the continuous breathing loop

    _animation = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedSize = widget.baseSize * _animation.value;
        return Container(
          width: animatedSize,
          height: animatedSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [widget.color, Colors.transparent],
              stops: const [0.2, 1.0],
            ),
          ),
        );
      },
    );
  }
}
