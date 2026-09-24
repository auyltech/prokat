import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class EditNameSheet extends ConsumerStatefulWidget {
  final String initialName;

  const EditNameSheet({super.key, required this.initialName});

  static Future<void> show({
    required BuildContext context,
    required String initialName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return AppBottomSheet.show<void>(
      context,
      title: l10n.editName,
      contentBuilder: (_) => EditNameSheet(initialName: initialName),
    );
  }

  @override
  ConsumerState<EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends ConsumerState<EditNameSheet> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> onSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final newName = controller.text.trim();
    if (newName.isEmpty) return;

    final parts = newName.split(' ');

    final success = await ref
        .read(clientProfileMutationProvider.notifier)
        .updateUserProfile(
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
        );

    if (mounted) {
      Navigator.pop(context);

      AppToast.show(
        message: success ? l10n.nameUpdated : l10n.failedSaveName,
        type: success ? AppToastType.success : AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(clientProfileMutationProvider).isLoading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimens.s16$base,
      children: [
        AppTextField(
          controller: controller,
          hint: l10n.enterName,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        Row(
          spacing: AppDimens.s12$md,
          children: [
            Expanded(
              child: AppElevatedButton(
                title: l10n.save,
                onTap: isLoading ? null : onSubmit,
                isLoading: isLoading,
              ),
            ),
            Expanded(
              child: AppOutlinedButton(
                title: l10n.cancel,
                onTap: isLoading ? null : () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
