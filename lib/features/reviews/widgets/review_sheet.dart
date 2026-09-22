import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/reviews/state/review_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ReviewSheet extends ConsumerStatefulWidget {
  final String bookingId;
  final String revieweeId;

  const ReviewSheet({
    super.key,
    required this.bookingId,
    required this.revieweeId,
  });

  static Future<bool> show(
    BuildContext context, {
    required String bookingId,
    required String revieweeId,
    required AppMode mode,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final title = mode == AppMode.clientMode
        ? l10n.reviewOwner
        : l10n.reviewClient;
    final submitted = await AppBottomSheet.show<bool>(
      context,
      title: title,
      contentBuilder: (context) =>
          ReviewSheet(bookingId: bookingId, revieweeId: revieweeId),
    );

    return submitted ?? false;
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
      AppToast.show(message: l10n.selectStars, type: AppToastType.error);
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
        AppToast.show(
          message: result ? l10n.reviewSubmitted : l10n.failedToSubmitReview,
          type: AppToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          message: e.toString().replaceFirst('Exception: ', ''),
          type: AppToastType.error,
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
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(reviewByBookingProvider(widget.bookingId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.s08$sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StarRow(
            value: _stars,
            onChanged: state.isSubmitting
                ? null
                : (v) => setState(() => _stars = v),
          ),

          const SizedBox(height: AppDimens.s12$md),

          AppTextArea(
            title: l10n.commentOptional,
            controller: _commentController,
            hint: '',
            minLines: 2,
            maxLines: 4,
          ),

          const SizedBox(height: AppDimens.s16$base),

          Row(
            children: [
              Expanded(
                child: AppElevatedButton(
                  title: l10n.submit,
                  onTap: state.isSubmitting ? null : onSubmit,
                  isLoading: state.isSubmitting,
                ),
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
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final star = index + 1;
          final isActive = star <= value;
          return IconButton(
            onPressed: onChanged == null ? null : () => onChanged!(star),
            iconSize: 40,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          );
        }),
      ),
    );
  }
}
