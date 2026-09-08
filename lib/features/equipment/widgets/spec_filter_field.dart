import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpecFilterField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? displayText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final VoidCallback onCleared;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const SpecFilterField({
    super.key,
    required this.label,
    required this.onCleared,
    this.hintText,
    this.displayText,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
    this.onTap,
  });

  bool get _isPicker => onTap != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (_isPicker) _PickerBox(field: this) else _TextBox(field: this),
      ],
    );
  }
}

class _TextBox extends StatelessWidget {
  final SpecFilterField field;

  const _TextBox({required this.field});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = field.controller!;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          maxLines: 1,
          maxLength: field.maxLength,
          keyboardType: field.keyboardType,
          inputFormatters: field.inputFormatters,
          onChanged: field.onChanged,
          style: theme.textTheme.bodyMedium,
          textAlignVertical: TextAlignVertical.center,
          decoration: _decoration(
            theme,
            hintText: field.hintText,
            suffix: _ClearIcon(
              enabled: value.text.trim().isNotEmpty,
              onPressed: field.onCleared,
            ),
          ).copyWith(counterText: ''),
        );
      },
    );
  }
}

class _PickerBox extends StatelessWidget {
  final SpecFilterField field;

  const _PickerBox({required this.field});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = (field.displayText ?? '').trim().isNotEmpty;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: field.onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          isEmpty: !hasValue,
          decoration: _decoration(
            theme,
            hintText: field.hintText,
            suffix: _ClearIcon(enabled: hasValue, onPressed: field.onCleared),
          ),
          child: Text(
            hasValue ? field.displayText! : (field.hintText ?? ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: hasValue
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ),
      ),
    );
  }
}

class _ClearIcon extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ClearIcon({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: enabled ? 0.6 : 0.25);

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(Icons.close, size: 18, color: color),
      onPressed: enabled ? onPressed : null,
    );
  }
}

InputDecoration _decoration(
  ThemeData theme, {
  required Widget suffix,
  String? hintText,
}) {
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(
      color: theme.colorScheme.outline.withValues(alpha: 0.5),
    ),
  );

  return InputDecoration(
    hintText: hintText,
    hintStyle: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
    ),
    filled: true,
    fillColor: theme.cardColor,
    isDense: true,
    contentPadding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
    border: outline,
    enabledBorder: outline,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    ),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
  );
}
