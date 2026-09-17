import 'package:flutter/material.dart';
import 'package:prokat/core/theme/legacy/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  _IndicatorDot(indicator: indicator),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.headingM(context),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        child,
                        if (showSave) ...[
                          const SizedBox(height: 16),
                          AppElevatedButton(
                            title: saveLabel,
                            onTap: saveEnabled && !saveLoading ? onSave : null,
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
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final BlockIndicator indicator;

  const _IndicatorDot({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color fill;
    final Color border;

    switch (indicator) {
      case BlockIndicator.valid:
        fill = AppTheme.validBlockIndicator(theme.brightness);
        border = fill;
      case BlockIndicator.invalid:
        fill = colorScheme.error;
        border = colorScheme.error;
      case BlockIndicator.empty:
        fill = Colors.transparent;
        border = colorScheme.outline;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 2),
      ),
    );
  }
}
