import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

class DemandOtherIntentCard extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? description;
  final TextEditingController provideController;
  final TextEditingController rentController;

  const DemandOtherIntentCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.description,
    required this.provideController,
    required this.rentController,
  });

  @override
  State<DemandOtherIntentCard> createState() => _DemandOtherIntentCardState();
}

class _DemandOtherIntentCardState extends State<DemandOtherIntentCard> {
  final _scrollController = ScrollController();
  final _provideFocus = FocusNode();
  final _rentFocus = FocusNode();
  final _provideKey = GlobalKey();
  final _rentKey = GlobalKey();

  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    _provideFocus.addListener(_onFocusChange);
    _rentFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _provideFocus
      ..removeListener(_onFocusChange)
      ..dispose();
    _rentFocus
      ..removeListener(_onFocusChange)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_provideFocus.hasFocus) {
      _scrollFocusedFieldIntoView(_provideKey);
    } else if (_rentFocus.hasFocus) {
      _scrollFocusedFieldIntoView(_rentKey);
    }
  }

  void _scrollFocusedFieldIntoView(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait for keyboard inset / padding to apply before scrolling.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 50), () async {
          if (!mounted) return;
          final fieldContext = key.currentContext;
          if (fieldContext == null || !fieldContext.mounted) return;
          await Scrollable.ensureVisible(
            fieldContext,
            alignment: 0.5,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset > _lastKeyboardInset &&
        (_provideFocus.hasFocus || _rentFocus.hasFocus)) {
      final key = _provideFocus.hasFocus ? _provideKey : _rentKey;
      _scrollFocusedFieldIntoView(key);
    }
    _lastKeyboardInset = keyboardInset;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: colors.background.elevated,
      borderRadius: BorderRadius.circular(AppDimens.r16$xl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.r16$xl),
          border: Border.all(color: colors.borders.main),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.s20$lg,
          0,
          AppDimens.s20$lg,
          0,
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            0,
            AppDimens.s16$base,
            0,
            AppDimens.s16$base + keyboardInset,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimens.s20$lg),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? OptimizedNetworkImage(
                        imageUrl: widget.imageUrl,
                        height: 160,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        Icons.agriculture_outlined,
                        size: 100,
                        color: colors.text.secondary,
                      ),
              ),
              const SizedBox(height: AppDimens.s32$xxl),
              Text(
                widget.title,
                style: AppFonts.headingM(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (widget.description != null &&
                  widget.description!.trim().isNotEmpty) ...[
                const SizedBox(height: AppDimens.s12$md),
                Text(
                  widget.description!,
                  style: AppFonts.body16(context),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppDimens.s32$xxl),
              KeyedSubtree(
                key: _provideKey,
                child: AppTextArea(
                  title: l10n.demandSurveyOtherProvidePrompt,
                  controller: widget.provideController,
                  focusNode: _provideFocus,
                  hint: l10n.demandSurveyOtherProvideHint,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 150,
                ),
              ),
              const SizedBox(height: AppDimens.s16$base),
              KeyedSubtree(
                key: _rentKey,
                child: AppTextArea(
                  title: l10n.demandSurveyOtherRentPrompt,
                  controller: widget.rentController,
                  focusNode: _rentFocus,
                  hint: l10n.demandSurveyOtherRentHint,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 150,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
