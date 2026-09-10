import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';

class AppTextArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? title;
  final String? hint;
  final String? errorText;
  final bool showError;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;

  const AppTextArea({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.title,
    this.hint,
    this.errorText,
    this.showError = true,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.validator,
    this.minLines = 3,
    this.maxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      title: title,
      hint: hint,
      errorText: errorText,
      showError: showError,
      enabled: enabled,
      readOnly: readOnly,
      keyboardType: keyboardType ?? TextInputType.multiline,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction ?? TextInputAction.newline,
      onChanged: onChanged,
      prefix: prefix,
      suffix: suffix,
      validator: validator,
      maxLines: maxLines,
    );
  }
}
