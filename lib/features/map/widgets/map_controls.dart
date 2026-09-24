import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

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
    // TODO(Vadim): пока скрыл. Эта функциональность не проверена и плохо подходит для флоу выбора адреса.
    // final selectedCategory = ref.watch(selectedCategoryProvider);
    const bgColor = Color(0xFF1E2125); // Card Charcoal

    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO(Vadim): пока скрыл. Эта функциональность не проверена и плохо подходит для флоу выбора адреса.
            // TODO(Vadim): пока скрыл. Здесь был функционал отображения (предположительно) доступной техники на карте по категориям для выбора ее с целью создания заявки на аренду.
            // /// 1. VIEW AS LIST (Catalog Icon)
            // _MapControlButton(
            //   icon: Icons.view_agenda_rounded, // Much better "Catalog" feel
            //   onPressed: () {
            //     final id = selectedCategory?.id ?? '';
            //     context.go('${AppRoutes.searchMap}?category=$id');
            //   },
            //   color: bgColor,
            //   iconColor: Colors.white,
            // ),

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
              clipBehavior: Clip.antiAlias,
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

  const _MapControlButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: icon,
      onTap: onPressed,
      variant: AppIconButtonVariant.outlined,
      tone: AppIconButtonTone.primary,
      shape: AppIconButtonShape.rounded,
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
    return AppIconButton(
      icon: icon,
      onTap: onTap,
      tone: AppIconButtonTone.inverse,
    );
  }
}
