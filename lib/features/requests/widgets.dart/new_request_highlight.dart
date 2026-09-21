import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/requests/providers/seen_requests_provider.dart';

/// Plays once, the first time a tender card is shown to this owner: the card
/// fades and slides in behind a primary-tinted wash that drains away.
/// Re-entering the screen renders the card plainly.
class NewRequestHighlight extends ConsumerStatefulWidget {
  const NewRequestHighlight({
    super.key,
    required this.requestId,
    required this.child,
  });

  final String requestId;
  final Widget child;

  @override
  ConsumerState<NewRequestHighlight> createState() =>
      _NewRequestHighlightState();
}

class _NewRequestHighlightState extends ConsumerState<NewRequestHighlight>
    with SingleTickerProviderStateMixin {
  late final bool _isFirstView;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _isFirstView = !ref.read(seenRequestIdsProvider).contains(widget.requestId);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (!_isFirstView) {
      _controller.value = 1;
      return;
    }

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(seenRequestIdsProvider.notifier).markSeen(widget.requestId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFirstView) return widget.child;

    final theme = Theme.of(context);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final progress = curved.value;
        return Opacity(
          opacity: 0.25 + (0.75 * progress),
          child: Transform.translate(
            offset: Offset(0, -10 * (1 - progress)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: 0.10 * (1 - progress),
                ),
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary.withValues(
                      alpha: 1 - progress,
                    ),
                    width: 3,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
