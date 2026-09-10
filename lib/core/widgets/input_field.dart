import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/widgets/shake_on_tick.dart';
import 'package:prokat/l10n/app_localizations.dart';

class InputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isNumeric;
  final bool isLast;
  final bool isRequired; // Added property
  final String? suffixText;
  final String? Function(String?)? validator;
  final IconData? icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final VoidCallback? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? requiredHintText;
  final String? errorText;
  final String? helperText;
  final String? requiredMessage;
  final bool readOnly;
  final bool showFieldErrors;
  final bool requiredHintMuted;
  final bool Function()? isBlank;
  final int shakeTick;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final int hintMaxLines;
  final bool boxed;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.isNumeric = false,
    this.isLast = false,
    this.isRequired = false, // Defaulted to false
    this.requiredMessage,
    this.validator,
    this.suffixText,
    this.icon,
    this.iconBgColor,
    this.iconColor,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.helperText,
    this.requiredHintText,
    this.readOnly = false,
    this.showFieldErrors = true,
    this.requiredHintMuted = false,
    this.isBlank,
    this.shakeTick = 0,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.hintMaxLines = 2,
    this.boxed = false,
  });

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant InputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBlank =
        widget.isBlank?.call() ?? widget.controller.text.trim().isEmpty;
    final showRequiredHint = widget.isRequired && isBlank;
    final requiredHintStyle = widget.requiredHintMuted
        ? theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.45),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
          )
        : theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w500,
          );
    final boxBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.45),
      ),
    );
    final focusedBoxBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    );
    final errorBoxBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.error),
    );

    return Row(
      crossAxisAlignment:
          widget.helperText != null ||
              widget.boxed ||
              (widget.maxLines ?? 1) > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Container(
            width: 45,
            height: 50,
            decoration: BoxDecoration(
              color: widget.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 25),
          ),

          const SizedBox(width: 12),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: Label and required indicator
              ShakeOnTick(
                tick: widget.shakeTick,
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      if (showRequiredHint &&
                          widget.requiredHintText != null &&
                          widget.requiredHintText!.isNotEmpty)
                        TextSpan(
                          text: ' ${widget.requiredHintText}',
                          style: requiredHintStyle,
                        )
                      else if (showRequiredHint)
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: widget.requiredHintMuted
                                ? colorScheme.onSurface.withValues(alpha: 0.45)
                                : theme.colorScheme.error,
                            fontStyle: widget.requiredHintMuted
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (widget.boxed) const SizedBox(height: 6),

              // Bottom row: Input field and suffix text
              Row(
                children: [
                  Expanded(
                    // Fixes layout crash by constraining the TextFormField width
                    child: TextFormField(
                      controller: widget.controller,
                      readOnly: widget.readOnly,
                      enableInteractiveSelection: !widget.readOnly,
                      canRequestFocus: !widget.readOnly,
                      minLines: widget.minLines,
                      maxLines: widget.maxLines,
                      maxLength: widget.maxLength,
                      validator: (value) {
                        if (!widget.showFieldErrors) return null;

                        final text = value?.trim() ?? '';
                        final isBlank = widget.isBlank?.call() ?? text.isEmpty;

                        if (widget.isRequired && isBlank) {
                          return widget.requiredMessage ??
                              AppLocalizations.of(context)?.fieldRequired;
                        }

                        return widget.validator?.call(value);
                      },
                      onChanged: (_) => widget.onChanged?.call(),
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      keyboardType: widget.isNumeric
                          ? TextInputType.number
                          : widget.keyboardType,
                      inputFormatters: widget.inputFormatters,
                      textInputAction: (widget.maxLines ?? 1) > 1
                          ? TextInputAction.newline
                          : widget.isLast
                          ? TextInputAction.done
                          : TextInputAction.next,
                      cursorColor: colorScheme.primary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.readOnly
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintMaxLines: widget.hintMaxLines,
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: !widget.boxed,
                        filled: widget.boxed || widget.readOnly,
                        fillColor: widget.boxed || widget.readOnly
                            ? colorScheme.surfaceContainerHighest
                            : null,
                        contentPadding: widget.boxed
                            ? const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              )
                            : const EdgeInsets.only(top: 4, bottom: 4),
                        counterText: widget.maxLength != null ? '' : null,
                        border: widget.boxed ? boxBorder : InputBorder.none,
                        errorBorder: widget.boxed
                            ? errorBoxBorder
                            : InputBorder.none,
                        focusedErrorBorder: widget.boxed
                            ? focusedBoxBorder
                            : InputBorder.none,
                        focusedBorder: widget.boxed
                            ? focusedBoxBorder
                            : InputBorder.none,
                        enabledBorder: widget.boxed
                            ? boxBorder
                            : InputBorder.none,
                        disabledBorder: widget.boxed
                            ? boxBorder
                            : InputBorder.none,
                        errorStyle: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (widget.suffixText != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        widget.suffixText!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              if (widget.helperText != null || widget.maxLength != null) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.helperText != null)
                      Expanded(
                        child: Text(
                          widget.helperText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.25,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (widget.maxLength != null)
                      Text(
                        '${widget.controller.text.length}/${widget.maxLength}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],

              if (widget.errorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
