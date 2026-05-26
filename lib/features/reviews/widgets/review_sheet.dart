import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';

class ReviewSheet extends ConsumerStatefulWidget {
  final String bookingId;
  final String revieweeId;
  final String title;

  const ReviewSheet({
    super.key,
    required this.bookingId,
    required this.revieweeId,
    required this.title,
  });

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  int _stars = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(reviewByBookingProvider(widget.bookingId));
    final notifier = ref.read(
      reviewByBookingProvider(widget.bookingId).notifier,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _StarRow(
            value: _stars,
            onChanged: state.isSubmitting
                ? null
                : (v) => setState(() => _stars = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comment (optional)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : () async {
                    if (_stars <= 0) {
                      AppSnackBar.show(
                        context,
                        message: 'Select stars',
                        isError: true,
                      );
                      return;
                    }
                    try {
                      if (!context.mounted) return;
                      Navigator.pop(context, true);

                      await notifier.createReview(
                        revieweeId: widget.revieweeId,
                        stars: _stars,
                        comment: _commentController.text.trim(),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      AppSnackBar.show(
                        context,
                        message: e.toString().replaceFirst('Exception: ', ''),
                        isError: true,
                      );
                    }
                  },
            child: state.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;

  const _StarRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        final isActive = star <= value;
        return IconButton(
          onPressed: onChanged == null ? null : () => onChanged!(star),
          icon: Icon(
            isActive ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isActive ? theme.colorScheme.primary : theme.disabledColor,
          ),
        );
      }),
    );
  }
}
