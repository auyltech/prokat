import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AdaptiveFooterCard extends StatelessWidget {
  final double progress;

  const AdaptiveFooterCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = progress > 0.5;

    return Container(
      margin: EdgeInsets.lerp(
        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        progress,
      ),
      child: Material(
        elevation: 8,
        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(isExpanded ? 20 : 20),
        color: theme.colorScheme.primary,
        child: InkWell(
          onTap: () => context.push(AppRoutes.searchList),
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.lerp(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              const EdgeInsets.all(24),
              progress,
            ),
            child: isExpanded
                ? Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -10,
                        child: Icon(
                          Icons.local_shipping_rounded,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),

                            const SizedBox(width: 20),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.findAndRent,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.browseHeavyEquipment,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _buildCollapsedContent(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          l10n.findAndRent,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
