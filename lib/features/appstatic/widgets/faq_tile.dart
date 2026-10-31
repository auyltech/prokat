import 'package:flutter/material.dart';
import 'package:prokat/features/support/models/faq_model.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/theme/app_dimens.dart';

class FaqTile extends StatelessWidget {
  final FaqModel faq;
  final String currentLocale;

  const FaqTile({super.key, required this.faq, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = faq.translation(currentLocale);
    final flow = ProkatFlowScope.maybeOf(context);

    return Container(
      margin: flow == null
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: AppDimens.s08$sm),
      clipBehavior: flow == null ? Clip.none : Clip.antiAlias,
      decoration: BoxDecoration(
        color: flow?.surface,
        borderRadius: flow == null
            ? null
            : BorderRadius.circular(AppDimens.r16$xl),
        border: flow == null
            ? const Border(bottom: BorderSide(color: Colors.grey, width: 1.2))
            : Border.all(color: flow.border),
      ),
      child: ExpansionTile(
        tilePadding: flow == null
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: AppDimens.s16$base),
        childrenPadding: flow == null
            ? const EdgeInsets.only(bottom: 16)
            : const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: flow == null ? null : const Border(),
        collapsedShape: flow == null ? null : const Border(),
        iconColor: flow?.primary ?? const Color(0xFF004699),
        collapsedIconColor: flow?.secondary ?? Colors.grey,
        title: Text(
          tr.question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: flow?.title ?? theme.colorScheme.onSurface,
          ),
        ),
        children: [
          Text(
            tr.answer,
            style: TextStyle(
              color: flow?.secondary ?? Colors.grey[700],
              height: 1.4,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
