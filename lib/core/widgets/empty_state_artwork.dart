import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';

/// Shared vector artwork: scales cleanly, follows the theme, contains no text.
class EmptyStateArtwork extends StatelessWidget {
  const EmptyStateArtwork({
    super.key,
    required this.imageName,
    this.compact = false,
  });

  final String imageName;
  final bool compact;

  static bool supports(String? name) => const {
    'empty_bookings.png',
    'empty_chats.png',
    'empty_requests.png',
    'empty_equipment.png',
    'empty_notifications.png',
    'empty_favorites.png',
    'empty_error.png',
    'connection_error.png',
  }.contains(name);

  @override
  Widget build(BuildContext context) {
    final palette = ProkatFlowPalette.of(context);
    final icon = switch (imageName) {
      'empty_bookings.png' => LucideIcons.calendarDays,
      'empty_chats.png' => LucideIcons.messagesSquare,
      'empty_requests.png' => LucideIcons.clipboardList,
      'empty_equipment.png' => LucideIcons.truck,
      'empty_notifications.png' => LucideIcons.bell,
      'empty_favorites.png' => LucideIcons.heart,
      'connection_error.png' => LucideIcons.wifiOff,
      _ => LucideIcons.cloudAlert,
    };
    return ExcludeSemantics(
      child: SizedBox(
        width: compact ? 72 : 220,
        height: compact ? 64 : 160,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 220,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 24,
                  top: 14,
                  child: Container(
                    width: 172,
                    height: 132,
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: BorderRadius.circular(66),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  child: _Dot(color: palette.border, size: 9),
                ),
                const Positioned(
                  right: 24,
                  top: 20,
                  child: _Dot(color: Color(0xFFF7BD42), size: 11),
                ),
                Positioned(
                  left: 28,
                  top: 34,
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 19,
                    color: palette.primary.withValues(alpha: 0.55),
                  ),
                ),
                Transform.rotate(
                  angle: -0.09,
                  child: Container(
                    width: 106,
                    height: 116,
                    margin: const EdgeInsets.only(right: 30, top: 8),
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Container(
                  width: 108,
                  height: 116,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.border),
                    boxShadow: [
                      BoxShadow(
                        color: palette.title.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 46, color: palette.primary),
                      const SizedBox(height: 13),
                      Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: palette.primarySoft,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 25,
                  bottom: 27,
                  child: Container(
                    width: 24,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: 42,
                  bottom: 8,
                  child: Container(
                    width: 136,
                    height: 2,
                    color: palette.border,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
