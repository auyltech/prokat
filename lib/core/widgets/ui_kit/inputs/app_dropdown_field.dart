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
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final Widget? prefix;
  final String sheetTitle;

  const AppDropdownField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.prefix,
    this.sheetTitle = 'Select',
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _labelFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _labelFor(widget.value);
    if (_controller.text != next) _controller.text = next;
  }

  @override
  void dispose() {
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
    if (!widget.enabled) return;
    final colors = context.colors;
    final useScrollable = widget.options.length >= 6;

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

    final selected = await open();
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedOption = widget.options
        .where((o) => o.value == widget.value)
        .firstOrNull;

    return AppTextField(
      controller: _controller,
      label: widget.label,
      hint: widget.hint,
      enabled: widget.enabled,
      readOnly: true,
      onTap: _openSheet,
      prefix: widget.prefix ?? selectedOption?.prefix,
      suffix: RotatedBox(
        quarterTurns: 3,
        child: AppIcons.appBarChevronLeft.call(
          size: AppDimens.s24$xl,
          color: colors.icons.main,
        ),
      ),
    );
  }
}
