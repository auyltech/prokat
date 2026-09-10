import 'package:flutter/material.dart';

class OverlayBadgeIcon extends StatelessWidget {
  final IconData icon;
  final IconData badge;
  final Color color;
  final Color badgeBackground;
  final double size;

  const OverlayBadgeIcon({
    super.key,
    required this.icon,
    required this.badge,
    required this.color,
    this.badgeBackground = Colors.white,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = size * 0.42;
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, size: size * 0.88, color: color),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize + 4,
              height: badgeSize + 4,
              decoration: BoxDecoration(
                color: badgeBackground,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.2),
              ),
              child: Icon(badge, size: badgeSize, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
