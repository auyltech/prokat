import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

class DemandSurveyCommentField extends StatelessWidget {
  final TextEditingController controller;

  const DemandSurveyCommentField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppTextArea(
      controller: controller,
      hint: l10n.demandSurveyOtherHint,
      minLines: 2,
      maxLines: 3,
    );
  }
}
