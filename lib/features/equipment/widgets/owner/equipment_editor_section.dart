import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/primary_button.dart';
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  child,
                  if (showSave) ...[
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: saveLabel,
                      onPressed: saveEnabled && !saveLoading ? onSave : null,
                      isLoading: saveLoading,
                    ),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 180),
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
    final colorScheme = Theme.of(context).colorScheme;
    final Color fill;
    final Color border;

    switch (indicator) {
      case BlockIndicator.valid:
        fill = colorScheme.tertiary;
        border = colorScheme.tertiary;
      case BlockIndicator.invalid:
        fill = colorScheme.error;
        border = colorScheme.error;
      case BlockIndicator.empty:
        fill = Colors.transparent;
        border = colorScheme.outline;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: 1.5),
      ),
    );
  }
}
