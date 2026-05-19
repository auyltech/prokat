import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  bool _showWarmupMessage = false;
  Timer? _warmupTimer;

  @override
  void initState() {
    super.initState();
    _warmupTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showWarmupMessage = true);
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.dark, // Use light if using a dark theme
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    // _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
    //   CurvedAnimation(parent: _controller, curve: const _OutProposedCurve()),
    // );

    _controller.forward();

    // Future.delayed(const Duration(seconds: 3), () {
    //   if (context.mounted) {
    //     context.go(AppRoutes.dashboard);
    //   }
    // });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _warmupTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = const Color(0xFF00489B);
    final textTheme = theme.textTheme;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        alignment: Alignment.center,
        children: [
          /// 1. Subtle Industrial Grid Pattern (Fills the "Empty" space)
          Opacity(
            opacity: 0.03,
            child: CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(accentColor),
            ),
          ),

          /// 2. Layered Background Glows
          Positioned(
            top: -150,
            right: -150,
            child: _BackgroundGlow(
              color: accentColor.withValues(alpha: 0.15),
              size: 600,
            ),
          ),

          /// 3. Main Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with "Glass" effect
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.precision_manufacturing_rounded,
                      size: 80,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Branding
                  RichText(
                    text: TextSpan(
                      style: textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        fontFamily: 'Oswald',
                        letterSpacing: 6,
                      ),
                      children: [
                        const TextSpan(text: 'PRO'),
                        TextSpan(
                          text: 'KAT',
                          style: TextStyle(color: accentColor),
                        ),
                      ],
                    ),
                  ),

                  // Subtle divider line to break the "emptiness"
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Text(
                    'HEAVY EQUIPMENT RENTALS',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 4. Bottom "Status" Area
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                // Linear progress feels more "industrial" than circular
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INITIALIZING SYSTEMS...',
                      style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      'v1.0.4',
                      style: textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showWarmupMessage) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Server is warming up, please wait...',
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: accentColor.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Painter for the background grid
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom curve for a "heavy / industrial" feel
// class _OutProposedCurve extends Curve {
//   const _OutProposedCurve();

//   @override
//   double transformInternal(double t) {
//     return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
//   }
// }

class _BackgroundGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _BackgroundGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.2, 1.0],
        ),
      ),
    );
  }
}
