import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

class RequiredFieldLabel extends StatelessWidget {
  const RequiredFieldLabel({
    super.key,
    required this.title,
    required this.showRequired,
    this.requiredHint,
  });

  final String title;
  final bool showRequired;

  /// Ignored — required mark matches [AppTextField] (` *`).
  final String? requiredHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(
      TextSpan(
        text: title,
        style: AppFonts.headingS(context),
        children: [
          if (showRequired)
            TextSpan(
              text: ' *',
              style: AppFonts.headingS(context)
                  .copyWith(color: colors.text.error),
            ),
        ],
      ),
    );
  }
}

class ChoicePair extends StatelessWidget {
  const ChoicePair({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.rightSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final bool rightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedButton<int>(
      isExpanded: true,
      value: leftSelected
          ? 0
          : rightSelected
          ? 1
          : null,
      segments: [
        AppSegmentedOption(title: leftLabel, value: 0),
        AppSegmentedOption(title: rightLabel, value: 1),
      ],
      onChanged: (value) {
        if (value == 0) {
          onLeft();
        } else {
          onRight();
        }
      },
    );
  }
}

/// Select-only field styled like [AppTextField], with [icon] as a leading prefix.
class OutlinePickerField extends StatefulWidget {
  const OutlinePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.isRequired = false,
    this.hint,
  });

  final String label;
  final String? value;
  final IconData icon;
  final Future<void> Function() onTap;
  final bool isRequired;
  final String? hint;

  @override
  State<OutlinePickerField> createState() => _OutlinePickerFieldState();
}

class _OutlinePickerFieldState extends State<OutlinePickerField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focusNode = FocusNode(canRequestFocus: false);
  }

  @override
  void didUpdateWidget(covariant OutlinePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value ?? '';
    if (_controller.text != next) _controller.text = next;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_pickerOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _pickerOpen = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _pickerOpen = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _focusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = context.colors.textField;

    return AppTextField(
      controller: _controller,
      focusNode: _focusNode,
      title: widget.label,
      hint: widget.hint,
      isRequired: widget.isRequired,
      selectOnly: true,
      forceFocused: _pickerOpen,
      onTap: _open,
      prefix: Icon(widget.icon, size: AppDimens.s20$lg, color: field.hint),
    );
  }
}
