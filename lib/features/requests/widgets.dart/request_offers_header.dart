import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';

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
    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: flow.title,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: 0.5).animate(animation),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: flow.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
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
