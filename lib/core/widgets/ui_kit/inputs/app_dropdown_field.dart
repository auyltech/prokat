import 'package:flutter/material.dart';
import 'package:prokat/core/theme/app_dimens.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/theme/app_icons.dart';
import 'package:prokat/core/theme/extensions/app_theme_getter.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/core/widgets/ui_kit/sheets/app_bottom_sheet.dart';

class DropdownOption<T> {
  final String label;
  final T value;
  final Widget? prefix;

  const DropdownOption({required this.label, required this.value, this.prefix});
}

class AppDropdownField<T> extends StatefulWidget {
  final String? title;
  final String? hint;
  final String? errorText;
  final T? value;
  final List<DropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;
  final Widget? prefix;
  final String sheetTitle;

  /// Called when the picker sheet closes (field leaves the active state).
  final VoidCallback? onFocusLost;

  const AppDropdownField({
    super.key,
    this.title,
    this.hint,
    this.errorText,
    this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.prefix,
    this.sheetTitle = 'Select',
    this.onFocusLost,
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _labelFor(widget.value));
    _focusNode = FocusNode(canRequestFocus: false);
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _labelFor(widget.value);
    if (_controller.text != next) _controller.text = next;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _labelFor(T? value) {
    if (value == null) return '';
    for (final option in widget.options) {
      if (option.value == value) return option.label;
    }
    return '';
  }

  Future<void> _openSheet() async {
    if (!widget.enabled || widget.readOnly || _pickerOpen) return;
    final colors = context.colors;
    final useScrollable = widget.options.length >= 6;

    // Chrome is driven by [_pickerOpen], not TextField focus — avoid sticky
    // focus after the sheet route restores the previous primary focus.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _pickerOpen = true);

    Future<T?> open() {
      if (useScrollable) {
        return AppBottomSheet.showScrollable<T>(
          context,
          title: widget.sheetTitle,
          headerBuilder: (_) => const SizedBox.shrink(),
          footerBuilder: (_) => const SizedBox.shrink(),
          scrollableListBuilder: (context, controller) {
            return ListView.builder(
              controller: controller,
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final selected = option.value == widget.value;
                return ListTile(
                  leading: option.prefix,
                  title: Text(option.label, style: AppFonts.body14(context)),
                  trailing: selected
                      ? AppIcons.check.call(
                          size: AppDimens.s20$lg,
                          color: colors.icons.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                );
              },
            );
          },
        );
      }

      return AppBottomSheet.show<T>(
        context,
        title: widget.sheetTitle,
        contentBuilder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in widget.options)
                ListTile(
                  leading: option.prefix,
                  title: Text(option.label, style: AppFonts.body14(context)),
                  trailing: option.value == widget.value
                      ? AppIcons.check.call(
                          size: AppDimens.s20$lg,
                          color: colors.icons.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
            ],
          );
        },
      );
    }

    try {
      final selected = await open();
      if (!mounted) return;
      setState(() => _pickerOpen = false);
      // Route pop may restore focus to this field on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      });
      if (selected != null) {
        // Do not call [onFocusLost] after a selection: callers often validate
        // against widget state that has not rebuilt with the new value yet,
        // which re-applies empty-field errors.
        widget.onChanged(selected);
      } else {
        widget.onFocusLost?.call();
      }
    } finally {
      if (mounted && _pickerOpen) {
        setState(() => _pickerOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedOption = widget.options
        .where((o) => o.value == widget.value)
        .firstOrNull;
    final canOpen = widget.enabled && !widget.readOnly;

    return AppTextField(
      controller: _controller,
      focusNode: _focusNode,
      title: widget.title,
      hint: widget.hint,
      errorText: widget.errorText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      isRequired: widget.isRequired,
      selectOnly: true,
      forceFocused: _pickerOpen,
      onTap: canOpen ? _openSheet : null,
      prefix: widget.prefix ?? selectedOption?.prefix,
      suffix: Icon(
        Icons.expand_more_rounded,
        size: AppDimens.s24$xl,
        color: colors.text.secondary,
      ),
    );
  }
}
