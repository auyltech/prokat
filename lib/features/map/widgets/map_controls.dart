import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:go_router/go_router.dart';

class MapControls extends ConsumerWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onChangeLocation;

  const MapControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(categoriesProvider).selectedCategory;
    const bgColor = Color(0xFF1E2125); // Card Charcoal
    const accentColor = Color(0xFF4E73DF); // Industrial Blue

    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 1. VIEW AS LIST (Catalog Icon)
            _MapControlButton(
              icon: Icons.view_agenda_rounded, // Much better "Catalog" feel
              onPressed: () {
                final id = selectedCategory?.id ?? '';
                context.go('${AppRoutes.searchMap}?category=$id');
              },
              color: bgColor,
              iconColor: Colors.white,
            ),

            const SizedBox(height: 24),

            /// 2. ZOOM GROUP (Fused Button)
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ZoomPart(
                    icon: Icons.add_rounded,
                    onTap: onZoomIn,
                    isTop: true,
                  ),
                  Container(
                    width: 24,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  _ZoomPart(
                    icon: Icons.remove_rounded,
                    onTap: onZoomOut,
                    isTop: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 3. MY LOCATION (Miniaturized)
            _MapControlButton(
              icon: Icons.my_location_rounded,
              onPressed: onChangeLocation,
              size: 42, // Smaller as requested
              iconSize: 20,
              color: bgColor,
              iconColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color color;
  final Color iconColor;

  const _MapControlButton({
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.iconSize = 24,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

class _ZoomPart extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isTop;

  const _ZoomPart({
    required this.icon,
    required this.onTap,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(isTop ? 14 : 0),
        bottom: Radius.circular(isTop ? 0 : 14),
      ),
      child: Container(
        height: 44,
        width: 44,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
