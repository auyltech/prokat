import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

class SpecFilterChoice {
  final String value;
  final String label;

  const SpecFilterChoice({required this.value, required this.label});
}

class SpecSelectSheet extends StatelessWidget {
  final String title;
  final List<SpecFilterChoice> options;
  final String? selectedValue;

  const SpecSelectSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
  });

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required List<SpecFilterChoice> options,
    String? selectedValue,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SpecSelectSheet(
        title: title,
        options: options,
        selectedValue: selectedValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SheetChrome(
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.value == selectedValue;

          return ListTile(
            title: Text(option.label),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
            onTap: () => Navigator.pop(context, option.value),
          );
        },
      ),
    );
  }
}

class SpecMultiSelectSheet extends StatefulWidget {
  final String title;
  final List<SpecFilterChoice> options;
  final Set<String> selected;

  const SpecMultiSelectSheet({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
  });

  static Future<Set<String>?> show({
    required BuildContext context,
    required String title,
    required List<SpecFilterChoice> options,
    required Set<String> selected,
  }) {
    return showModalBottomSheet<Set<String>?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SpecMultiSelectSheet(
        title: title,
        options: options,
        selected: selected,
      ),
    );
  }

  @override
  State<SpecMultiSelectSheet> createState() => _SpecMultiSelectSheetState();
}

class _SpecMultiSelectSheetState extends State<SpecMultiSelectSheet> {
  late final Set<String> _draft;

  @override
  void initState() {
    super.initState();
    _draft = {...widget.selected};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return _SheetChrome(
      title: widget.title,
      footer: SizedBox(
        width: double.infinity,
        child: ActionButton(
          label: l10n.apply,
          onPressed: () => Navigator.pop(context, {..._draft}),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final checked = _draft.contains(option.value);

          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: checked,
            checkColor: Colors.white,
            title: Text(option.label, style: theme.textTheme.bodyMedium),
            onChanged: (next) => setState(() {
              if (next == true) {
                _draft.add(option.value);
              } else {
                _draft.remove(option.value);
              }
            }),
          );
        },
      ),
    );
  }
}

class _SheetChrome extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;

  const _SheetChrome({required this.title, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(child: child),
              if (footer != null) ...[const SizedBox(height: 12), footer!],
            ],
          ),
        ),
      ),
    );
  }
}
