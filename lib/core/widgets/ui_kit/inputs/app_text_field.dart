import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/app_icons.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_input_field_box.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_input_field_style.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? title;
  final String? hint;
  final String? errorText;
  final bool showError;
  final bool enabled;
  final bool readOnly;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int maxLines;

  const AppTextField({
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
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefix,
    this.suffix,
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
  }

  void _attachFocusNode(FocusNode? node) {
    if (node != null) {
      _focusNode = node;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _detachFocusNode() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _detachFocusNode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fieldTheme = colors.textField;
    final hasError =
        widget.showError &&
        widget.errorText != null &&
        widget.errorText!.isNotEmpty;
    final background = !widget.enabled
        ? fieldTheme.backgroundDisabled
        : (_focused ? fieldTheme.backgroundFocused : fieldTheme.background);
    final textColor = widget.enabled
        ? fieldTheme.text
        : fieldTheme.textDisabled;

    final obscureActive = widget.obscure && _obscured;
    final field = widget.validator != null
        ? TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscureText: obscureActive,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            validator: widget.validator,
            style: AppFonts.body14(context).copyWith(color: textColor),
            cursorColor: fieldTheme.cursor,
            decoration: _decoration(context, hasError: hasError),
          )
        : TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            obscureText: obscureActive,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            style: AppFonts.body14(context).copyWith(color: textColor),
            cursorColor: fieldTheme.cursor,
            decoration: _decoration(context, hasError: hasError),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimens.inputLabelGap,
      children: [
        if (widget.title != null)
          Text(widget.title!, style: AppFonts.label(context)),
        if (widget.label != null)
          Text(widget.label!, style: AppFonts.caption(context)),
        AppInputFieldBox(
          isFocused: _focused,
          hasError: hasError,
          backgroundColor: background,
          height: widget.maxLines == 1 ? AppDimens.inputHeight : null,
          minHeight: widget.maxLines == 1 ? null : AppDimens.inputHeight,
          child: field,
        ),
        if (hasError)
          Text(
            widget.errorText!,
            style: AppFonts.caption(context).copyWith(color: colors.text.error),
          ),
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, {required bool hasError}) {
    final fieldTheme = context.colors.textField;
    Widget? suffix = widget.suffix;
    if (widget.obscure) {
      suffix = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?suffix,
          GestureDetector(
            onTap: () => setState(() => _obscured = !_obscured),
            child: (_obscured ? AppIcons.eyeClose : AppIcons.eyeOpen).call(
              size: AppDimens.s20$lg,
              color: fieldTheme.hint,
            ),
          ),
        ],
      );
    }

    return InputDecoration(
      isDense: true,
      hintText: widget.hint,
      hintStyle: AppFonts.body14(context).copyWith(color: fieldTheme.hint),
      border: AppInputFieldStyle.noBorder,
      enabledBorder: AppInputFieldStyle.noBorder,
      focusedBorder: AppInputFieldStyle.noBorder,
      errorBorder: AppInputFieldStyle.noBorder,
      disabledBorder: AppInputFieldStyle.noBorder,
      focusedErrorBorder: AppInputFieldStyle.noBorder,
      errorStyle: AppFonts.collapsed,
      contentPadding: AppInputFieldStyle.contentPadding,
      prefixIcon: widget.prefix,
      prefixIconConstraints: AppInputFieldStyle.affixIconConstraints,
      suffixIcon: suffix,
      suffixIconConstraints: AppInputFieldStyle.affixIconConstraints,
    );
  }
}
