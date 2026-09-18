import 'package:flutter/material.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AppKzPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? title;
  final String hint;
  final String? errorText;
  final bool showError;
  final bool enabled;
  final bool readOnly;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFocusLost;
  final Widget? prefix;
  final String? Function(String?)? validator;

  const AppKzPhoneField({
    super.key,
    required this.controller,
    this.focusNode,
    this.title,
    required this.hint,
    this.errorText,
    this.showError = true,
    this.enabled = true,
    this.readOnly = false,
    this.isRequired = false,
    this.onChanged,
    this.onFocusLost,
    this.prefix,
    this.validator,
  });

  @override
  State<AppKzPhoneField> createState() => _AppKzPhoneFieldState();
}

class _AppKzPhoneFieldState extends State<AppKzPhoneField> {
  final _formatter = KzPhoneMaskFormatter();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_restorePrefixIfCleared);
    _restorePrefixIfCleared();
  }

  @override
  void didUpdateWidget(covariant AppKzPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_restorePrefixIfCleared);
    widget.controller.addListener(_restorePrefixIfCleared);
    _restorePrefixIfCleared();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_restorePrefixIfCleared);
    super.dispose();
  }

  void _restorePrefixIfCleared() {
    if (widget.controller.text.isNotEmpty) return;
    widget.controller.value = kzPhoneEditingValue(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      title: widget.title,
      hint: widget.hint,
      errorText: widget.errorText,
      showError: widget.showError,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      isRequired: widget.isRequired,
      keyboardType: TextInputType.phone,
      inputFormatters: [_formatter],
      onChanged: widget.onChanged,
      onFocusLost: widget.onFocusLost,
      prefix: widget.prefix,
      validator:
          widget.validator ??
          (value) {
            if (normalizeKzPhone(value) == null) {
              return l10n.enterValidPhoneNumber;
            }
            return null;
          },
    );
  }
}
