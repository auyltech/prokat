import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class CompanyAccentBorder extends StatefulWidget {
  final Widget child;
  const CompanyAccentBorder({super.key, required this.child});
  @override
  State<CompanyAccentBorder> createState() => _CompanyAccentBorderState();
}

class _CompanyAccentBorderState extends State<CompanyAccentBorder>
    with WidgetsBindingObserver {
  final animation = ValueNotifier<double>(0);
  Timer? timer;
  double phase = 0;
  bool resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void syncAnimation() {
    timer?.cancel();
    timer = null;
    if (!resumed ||
        MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.overlaps(Offset.zero & MediaQuery.sizeOf(context))) return;
      phase += .0125;
      animation.value = (1 + math.sin(phase)) / 2;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    resumed = state == AppLifecycleState.resumed;
    syncAnimation();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(painter: _BorderPainter(animation), child: widget.child),
  );
}

class _BorderPainter extends CustomPainter {
  final ValueNotifier<double> animation;
  _BorderPainter(this.animation) : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + animation.value, -1),
        end: Alignment(1, 1 - animation.value),
        colors: const [Color(0xFF381727), Color(0xFF762E47), Color(0xFF472035)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    final sparks = Paint()
      ..color = const Color(0xFFFFD3DC).withValues(alpha: .20);
    for (var i = 0; i < 7; i++) {
      final x = size.width * ((i * .137 + animation.value * .04) % 1);
      final y =
          size.height *
          (.2 + .6 * (1 + math.sin(i * 2.1 + animation.value * math.pi)) / 2);
      canvas.drawCircle(Offset(x, y), i.isEven ? 1.5 : 1, sparks);
    }
  }

  @override
  bool shouldRepaint(covariant _BorderPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
