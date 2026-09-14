import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/widgets/fullscreen_image_gallery.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/page_dots_indicator.dart';

class EquipmentImageHeader extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final Widget? overlay;

  const EquipmentImageHeader({
    super.key,
    required this.imageUrls,
    this.height = 220,
    this.overlay,
  });

  @override
  State<EquipmentImageHeader> createState() => _EquipmentImageHeaderState();
}

class _EquipmentImageHeaderState extends State<EquipmentImageHeader> {
  late final PageController _pageController;
  int _currentIndex = 0;

  List<String> get _urls => widget.imageUrls
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant EquipmentImageHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = _urls.length;
    if (_currentIndex >= count && count > 0) {
      setState(() => _currentIndex = count - 1);
    } else if (count == 0 && _currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openGallery(int index) {
    final urls = _urls;
    if (urls.isEmpty) return;
    FullscreenImageGallery.show(
      context: context,
      imageUrls: urls,
      initialIndex: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final urls = _urls;

    return ClipRRect(
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: urls.isEmpty
                ? ColoredBox(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      size: 40,
                    ),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: urls.length,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openGallery(index),
                        child: OptimizedNetworkImage(
                          imageUrl: urls[index],
                          fit: BoxFit.cover,
                          maxCacheHeight: 900,
                          fallbackIcon: Icons.image_not_supported,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      );
                    },
                  ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppDimens.s12$md,
              child: PageDotsIndicator(
                count: urls.length,
                index: _currentIndex,
              ),
            ),
          if (widget.overlay != null) Positioned.fill(child: widget.overlay!),
        ],
      ),
    );
  }
}
