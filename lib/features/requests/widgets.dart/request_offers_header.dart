import 'package:flutter/material.dart';

class RequestOffersHeader extends StatelessWidget {
  final String title;
  final Animation<double> animation;
  final VoidCallback onTap;

  const RequestOffersHeader({
    super.key,
    required this.title,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.5).animate(animation),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              height: 1,
              thickness: 1,
            ),
          ],
        ),
      ),
    );
  }
}
