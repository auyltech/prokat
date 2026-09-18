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
  final String? title;
  final String? hint;
  final String? errorText;
  final bool showError;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;

  /// Disables typing (dropdown / city picker) without applying [readOnly] chrome.
  final bool selectOnly;

  /// Keeps focused chrome while an external picker/sheet is open.
  final bool forceFocused;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFocusLost;
  final VoidCallback? onTap;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int? minLines;
  final int maxLines;
  final int? maxLength;

  const AppTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.title,
    this.hint,
    this.errorText,
    this.showError = true,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.selectOnly = false,
    this.forceFocused = false,
    this.obscure = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onFocusLost,
    this.onTap,
    this.prefix,
    this.suffix,
    this.validator,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
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
    widget.controller.addListener(_onControllerChanged);
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
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
    if (!_focusNode.hasFocus) widget.onFocusLost?.call();
  }

  void _onControllerChanged() {
    if (mounted && widget.maxLength != null) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
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
    final chromeReadOnly = widget.readOnly;
    final textInputReadOnly = widget.readOnly || widget.selectOnly;
    final showFocusChrome =
        widget.enabled &&
        !chromeReadOnly &&
        (widget.selectOnly ? widget.forceFocused : _focused);
    final background = !widget.enabled
        ? fieldTheme.backgroundDisabled
        : (showFocusChrome
              ? fieldTheme.backgroundFocused
              : fieldTheme.background);
    final textColor = (!widget.enabled || chromeReadOnly)
        ? fieldTheme.textDisabled
        : fieldTheme.text;
    final textStyle = AppFonts.body16(context).copyWith(
      color: textColor,
      height: 1.3,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final title = widget.title?.trim();
    final hasTitle = title != null && title.isNotEmpty;
    final showRequiredMark = widget.isRequired && hasTitle && !chromeReadOnly;

    final obscureActive = widget.obscure && _obscured;
    final field = widget.validator != null
        ? TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: textInputReadOnly,
            obscureText: obscureActive,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            minLines: widget.obscure ? 1 : widget.minLines,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            validator: widget.validator,
            style: textStyle,
            cursorColor: fieldTheme.cursor,
            decoration: _decoration(context, hasError: hasError),
          )
        : TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: textInputReadOnly,
            obscureText: obscureActive,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            minLines: widget.obscure ? 1 : widget.minLines,
            maxLines: widget.obscure ? 1 : widget.maxLines,
            maxLength: widget.maxLength,
            style: textStyle,
            cursorColor: fieldTheme.cursor,
            decoration: _decoration(context, hasError: hasError),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimens.inputLabelGap,
      children: [
        if (hasTitle)
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    style: AppFonts.headingS(context),
                    children: [
                      if (showRequiredMark)
                        TextSpan(
                          text: ' *',
                          style: AppFonts.headingS(context)
                              .copyWith(color: colors.text.error),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.maxLength != null && !widget.readOnly)
                Text(
                  '${widget.controller.text.length}/${widget.maxLength}',
                  style: AppFonts.caption(context)
                      .copyWith(color: colors.text.tertiary),
                ),
            ],
          ),
        AppInputFieldBox(
          isFocused: showFocusChrome,
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
      hintStyle: AppFonts.body16(context).copyWith(color: fieldTheme.hint),
      border: AppInputFieldStyle.noBorder,
      enabledBorder: AppInputFieldStyle.noBorder,
      focusedBorder: AppInputFieldStyle.noBorder,
      errorBorder: AppInputFieldStyle.noBorder,
      disabledBorder: AppInputFieldStyle.noBorder,
      focusedErrorBorder: AppInputFieldStyle.noBorder,
      errorStyle: AppFonts.collapsed,
      counterText: widget.maxLength == null ? null : '',
      contentPadding: AppInputFieldStyle.contentPadding,
      prefixIcon: widget.prefix == null
          ? null
          : Padding(
              padding: AppInputFieldStyle.prefixIconPadding,
              child: widget.prefix,
            ),
      prefixIconConstraints: AppInputFieldStyle.affixIconConstraints,
      suffixIcon: suffix == null
          ? null
          : Padding(
              padding: AppInputFieldStyle.suffixIconPadding,
              child: suffix,
            ),
      suffixIconConstraints: AppInputFieldStyle.affixIconConstraints,
    );
  }
}
