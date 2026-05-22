import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/page_header.dart';
import 'package:prokat/l10n/app_localizations.dart';

class MapContainer extends StatefulWidget {
  final Widget mobileMap;
  final String redirectRoute;
  final String redirectLabel;
  final String title;

  /// 👇 NEW
  final bool? showFallback;

  const MapContainer({
    super.key,
    required this.mobileMap,
    required this.redirectRoute,
    required this.redirectLabel,
    required this.title,
    this.showFallback, // null = auto redirect
  });

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  bool _didRedirect = false;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _shouldRedirect =>
      !_isMobile &&
      (widget.showFallback == null || widget.showFallback == false);

  @override
  void initState() {
    super.initState();

    if (_shouldRedirect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_didRedirect) {
          _didRedirect = true;
          context.go(widget.redirectRoute);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    /// ✅ MOBILE → show map
    if (_isMobile) {
      return widget.mobileMap;
    }

    /// 🔁 REDIRECT MODE → temporary empty screen
    if (_shouldRedirect) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /// 🧱 FALLBACK MODE
    return Scaffold(
      backgroundColor: const Color(0xFF121417),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2125),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PageHeader(title: widget.title),
                const SizedBox(height: 32),

                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: const Color(0xFFD97706),
                ),

                const SizedBox(height: 24),

                Text(
                  l10n.hardwareRestriction,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  l10n.mapMobileOnly,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(widget.redirectRoute),
                    icon: const Icon(Icons.list_alt_rounded),
                    label: Text(
                      widget.redirectLabel.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E73DF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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
