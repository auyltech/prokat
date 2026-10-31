import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/l10n/app_localizations.dart';

String _formatLaunchVersion(PackageInfo packageInfo) {
  final version = packageInfo.version.trim();
  final buildNumber = packageInfo.buildNumber.trim();

  if (version.isEmpty) return '';
  if (buildNumber.isEmpty) return 'v$version';
  return 'v$version+$buildNumber';
}

String _startupStepLabel(AppStartupStep step, AppLocalizations l10n) {
  return switch (step) {
    AppStartupStep.loadSavedMode => l10n.startupLoadingMode,
    AppStartupStep.restoreSession => l10n.startupRestoringSession,
    AppStartupStep.restoreOtpSession => l10n.startupRestoringOtp,
    AppStartupStep.refreshSession => l10n.startupRefreshingSession,
    AppStartupStep.fetchProfileMinimal => l10n.startupLoadingProfile,
    AppStartupStep.decideRoute => l10n.startupFinalizing,
    AppStartupStep.done => l10n.done,
  };
}

class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _showWarmupMessage = false;
  Timer? _warmupTimer;
  String _appVersionLabel = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadAppVersion());
    _warmupTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showWarmupMessage = true);
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(
      begin: .92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    unawaited(_controller.forward());
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersionLabel = _formatLaunchVersion(packageInfo));
    } catch (_) {
      // Version is informational; keep the splash usable if lookup fails.
    }
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    _warmupTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final startup = ref.watch(appStartupProvider);
    const palette = ProkatFlowPalette.light;
    const showDetails = kDebugMode;
    final progress = startup.progress.clamp(0.0, 1.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ProkatFlowPalette.brandNavy,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ProkatFlowPalette.brandNavy,
                palette.filledPrimary.withValues(alpha: .35),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GridPainter(Colors.white.withValues(alpha: .04)),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: MediaQuery.disableAnimationsOf(context)
                                  ? const AlwaysStoppedAnimation(1)
                                  : _fadeAnimation,
                              child: ScaleTransition(
                                scale: MediaQuery.disableAnimationsOf(context)
                                    ? const AlwaysStoppedAnimation(1)
                                    : _scaleAnimation,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.asset(
                                        'assets/icons/app_icon.png',
                                        width: 88,
                                        height: 88,
                                        cacheWidth: 256,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(text: 'PRO'),
                                          TextSpan(
                                            text: 'KAT',
                                            style: TextStyle(
                                              color: palette.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      style: const TextStyle(
                                        fontFamily: AppFonts.manropeFamily,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.heavyEquipmentRentals,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.manropeFamily,
                                        fontSize: 16,
                                        height: 1.4,
                                        color: Color(0xFFB9CBF3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 36),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: showDetails ? progress : null,
                                      minHeight: 4,
                                      color: palette.primary,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: .12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          showDetails
                                              ? _startupStepLabel(
                                                  startup.step,
                                                  l10n,
                                                )
                                              : l10n.loading,
                                          style: const TextStyle(
                                            fontFamily: AppFonts.manropeFamily,
                                            fontSize: 12,
                                            height: 1.4,
                                            color: Color(0xFFB9CBF3),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        showDetails
                                            ? '${(progress * 100).round()}%'
                                            : _appVersionLabel,
                                        style: const TextStyle(
                                          fontFamily: AppFonts.manropeFamily,
                                          fontSize: 12,
                                          color: Color(0xFFB9CBF3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_showWarmupMessage) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.serverWarmingUp,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.manropeFamily,
                                        fontSize: 12,
                                        height: 1.4,
                                        color: Color(0xFFB9CBF3),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
