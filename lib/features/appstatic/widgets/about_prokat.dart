import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class AboutProkatSection extends StatelessWidget {
  const AboutProkatSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Using your exact header brand color as the base anchors
    const brandDarkBlue = Color(0xFF002C63);
    const brandElectricBlue = Color(0xFF0056C6);

    return SliverPadding(
      padding: const EdgeInsets.all(0),
      sliver: SliverToBoxAdapter(
        child: Container(
          width: double.infinity,
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            boxShadow: [
              BoxShadow(
                color: brandDarkBlue.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [brandDarkBlue, Color(0xFF001838)],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. Creative UI Background Elements (Abstract modern glowing rings)
                Positioned(
                  right: -40,
                  top: -40,
                  child: _buildBackgroundCircle(
                    brandElectricBlue.withValues(alpha: 0.15),
                    180,
                  ),
                ),
                Positioned(
                  right: -10,
                  bottom: -50,
                  child: _buildBackgroundCircle(
                    brandElectricBlue.withValues(alpha: 0.25),
                    130,
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: -20,
                  child: Transform.rotate(
                    angle: -math.pi / 6,
                    child: Icon(
                      Icons.construction_rounded,
                      size: 140,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                // 2. Main Foreground Interactive Content Layer
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/about'),
                    splashColor: brandElectricBlue.withValues(alpha: 0.2),
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'NEW TO PROKAT?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Explore How It Works',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Find or rent heavy equipment and trusted service providers instantly in one tap.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    height: 1.35,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Floating circular forward action button
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: brandDarkBlue,
                              size: 20,
                            ),
                          ),
                        ],
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

  Widget _buildBackgroundCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
        border: Border.all(color: color, width: 24),
      ),
    );
  }
}
