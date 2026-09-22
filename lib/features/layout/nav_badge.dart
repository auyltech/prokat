import 'package:flutter/material.dart';

/// Counter bubble pinned to the top-right corner of a navigation icon.
///
/// `pulse` is meant for chat: a slow, low-contrast breath that draws the eye
/// without animating the whole bar. The bubble is hidden when [count] is 0.
class NavIconBadge extends StatefulWidget {
  const NavIconBadge({
    super.key,
    required this.child,
    required this.count,
    required this.color,
    this.pulse = false,
  });

  final Widget child;
  final int count;
  final Color color;
  final bool pulse;

  static const int maxCount = 99;

  @override
  State<NavIconBadge> createState() => _NavIconBadgeState();
}

class _NavIconBadgeState extends State<NavIconBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant NavIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final shouldPulse = widget.pulse && widget.count > 0;
    if (shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return widget.child;

    final theme = Theme.of(context);
    final capped = widget.count > NavIconBadge.maxCount;
    final text = capped
        ? '+${NavIconBadge.maxCount}'
        : '+${widget.count}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: -6,
          right: -12,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.55).animate(_controller),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.12).animate(_controller),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.cardColor, width: 1.5),
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
