import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_bar_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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

  static Future<bool> show(
    BuildContext context, {
    required String bookingId,
    required String revieweeId,
    required AppMode mode,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReviewSheet(
        bookingId: bookingId,
        revieweeId: revieweeId,
        title: mode == AppMode.clientMode
            ? l10n.reviewOwner
            : l10n.reviewClient,
      ),
    );
  }

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  int _stars = 0;
  final TextEditingController _commentController = TextEditingController();

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_stars <= 0) {
      AppSnackBar.show(message: l10n.selectStars, isError: true);
      return;
    }
    try {
      if (!context.mounted) return;

      Navigator.pop(context, true);

      final result = await ref
          .read(reviewByBookingProvider(widget.bookingId).notifier)
          .createReview(
            revieweeId: widget.revieweeId,
            stars: _stars,
            comment: _commentController.text.trim(),
          );

      if (mounted) {
        AppSnackBar.show(
          message: result ? l10n.reviewSubmitted : l10n.failedToSubmitReview,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          message: e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(reviewByBookingProvider(widget.bookingId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Text(
            widget.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),

          _StarRow(
            value: _stars,
            onChanged: state.isSubmitting
                ? null
                : (v) => setState(() => _stars = v),
          ),

          InputField(
            label: l10n.commentOptional,
            controller: _commentController,
            hint: "",
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ActionBarButton(label: l10n.submit, onPressed: onSubmit),
              ),
            ],
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
