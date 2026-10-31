import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';

class EquipmentEditorSection extends StatelessWidget {
  final String title;
  final BlockIndicator indicator;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final Widget child;
  final bool showSave;
  final bool saveEnabled;
  final bool saveLoading;
  final VoidCallback? onSave;
  final String saveLabel;

  const EquipmentEditorSection({
    super.key,
    required this.title,
    required this.indicator,
    required this.expanded,
    required this.onToggleExpanded,
    required this.child,
    required this.saveLabel,
    this.showSave = false,
    this.saveEnabled = false,
    this.saveLoading = false,
    this.onSave,
  });

  static const BorderRadius _cardRadius = BorderRadius.all(
    Radius.circular(AppDimens.r20$xxl),
  );

  static const BorderRadius _headerExpandedRadius = BorderRadius.vertical(
    top: Radius.circular(AppDimens.r20$xxl),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final flow = ProkatFlowScope.maybeOf(context);
    final headerRadius = expanded ? _headerExpandedRadius : _cardRadius;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.s16$base),
      child: Material(
        color: flow?.surface ?? colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: flow?.border ?? colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggleExpanded,
              borderRadius: headerRadius,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.s16$base,
                  AppDimens.s12$md,
                  AppDimens.s12$md,
                  AppDimens.s12$md,
                ),
                child: Row(
                  spacing: AppDimens.s12$md,
                  children: [
                    _IndicatorDot(indicator: indicator),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: flow == null ? 1 : null,
                        overflow: flow == null
                            ? TextOverflow.ellipsis
                            : TextOverflow.visible,
                        style: flow == null
                            ? AppFonts.headingM(context)
                            : AppFonts.headingS(context)
                                  .copyWith(color: flow.title),
                      ),
                    ),
                    Icon(
                      flow != null
                          ? expanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown
                          : expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: flow?.secondary ?? colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppDimens.defaultAnimationDuration,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.s16$base,
                        0,
                        AppDimens.s16$base,
                        AppDimens.s16$base,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          child,
                          if (showSave) ...[
                            const SizedBox(height: AppDimens.s16$base),
                            if (flow != null)
                              ProkatFlowPrimaryButton(
                                title: saveLabel,
                                onPressed: saveEnabled && !saveLoading
                                    ? onSave
                                    : null,
                                loading: saveLoading,
                              )
                            else
                              AppElevatedButton(
                                title: saveLabel,
                                onTap: saveEnabled && !saveLoading
                                    ? onSave
                                    : null,
                                isLoading: saveLoading,
                              ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final BlockIndicator indicator;

  const _IndicatorDot({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final flow = ProkatFlowScope.maybeOf(context);

    late final Color fill;
    late final Color border;
    IconData? icon;

    switch (indicator) {
      case BlockIndicator.valid:
        fill = flow?.success ?? AppTheme.validBlockIndicator(theme.brightness);
        border = fill;
        icon = flow == null ? Icons.check_rounded : LucideIcons.check;
      case BlockIndicator.invalid:
        fill = colors.borders.error;
        border = fill;
        icon = Icons.priority_high_rounded;
      case BlockIndicator.empty:
        fill = Colors.transparent;
        border = flow?.secondary ?? colors.text.tertiary;
    }

    return Container(
      width: AppDimens.checkboxSize,
      height: AppDimens.checkboxSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: AppDimens.inputBorderWidth),
      ),
      alignment: Alignment.center,
      child: flow != null && indicator == BlockIndicator.invalid
          ? const Text(
              '!',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppDimens.s12$md,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            )
          : icon == null
          ? null
          : Icon(icon, size: AppDimens.s12$md, color: colors.text.white),
    );
  }
}
