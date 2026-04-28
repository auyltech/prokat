import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/inline_tile.dart';

class CreateRequestTile extends StatelessWidget {
  const CreateRequestTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.clientRequestsCreate),
      child: InlineTile(
        child: Row(
          children: [
            // Enhanced Icon Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.25),
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.add,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),

            const SizedBox(width: 18),

            // Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create a request",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5, // Tighter tracking for modern look
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Post what you need and get offers",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.8,
                      ),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Subtle Trailing Arrow
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
