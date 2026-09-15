import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/page_dots_indicator.dart';

class FullscreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> imageUrls,
    int initialIndex = 0,
  }) {
    final urls = imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (urls.isEmpty) return Future.value();

    final safeIndex = initialIndex.clamp(0, urls.length - 1);

    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        fullscreenDialog: true,
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenImageGallery(
            imageUrls: urls,
            initialIndex: safeIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullscreenImageGallery> createState() => _FullscreenImageGalleryState();
}

class _FullscreenImageGalleryState extends State<FullscreenImageGallery> {
  late final PageController _pageController;
  late int _currentIndex;
  late final List<TransformationController> _transformControllers;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformControllers = List.generate(
      widget.imageUrls.length,
      (_) => TransformationController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onInteraction(int index) {
    final scale = _transformControllers[index].value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _resetZoom(int index) {
    _transformControllers[index].value = Matrix4.identity();
    if (_isZoomed) {
      setState(() => _isZoomed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              physics: _isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: (index) {
                _resetZoom(_currentIndex);
                setState(() {
                  _currentIndex = index;
                  _isZoomed = false;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onDoubleTap: () => _resetZoom(index),
                  child: InteractiveViewer(
                    transformationController: _transformControllers[index],
                    minScale: 1,
                    maxScale: 4,
                    onInteractionUpdate: (_) => _onInteraction(index),
                    onInteractionEnd: (_) => _onInteraction(index),
                    child: Center(
                      child: OptimizedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.contain,
                        maxCacheHeight: 1600,
                        fallbackIcon: Icons.image_not_supported_outlined,
                        backgroundColor: Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: topInset + AppDimens.s08$sm,
              left: AppDimens.s08$sm,
              child: FloatingActionButton.small(
                heroTag: 'fullscreen_image_gallery_back',
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).maybePop(),
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                elevation: 0,
                child: const Icon(Icons.chevron_left, color: Colors.white),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + AppDimens.s16$base,
                child: PageDotsIndicator(
                  count: widget.imageUrls.length,
                  index: _currentIndex,
                  elevated: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
