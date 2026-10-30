import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';

class AccountStatusCard extends StatelessWidget {
  final bool isOnline;
  final String title, subtitle;
  final String? explanation;
  final ValueChanged<bool>? onChanged;
  const AccountStatusCard({
    super.key,
    required this.isOnline,
    required this.title,
    required this.subtitle,
    this.explanation,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final flow = ProkatFlowScope.maybeOf(context);
    if (flow != null) {
      return AppCard(
        padding: const EdgeInsets.all(AppDimens.s16$base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 5,
                  backgroundColor: isOnline ? flow.success : flow.secondary,
                ),
                const SizedBox(width: AppDimens.s12$md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppFonts.body16SemiBold(context)
                            .copyWith(color: flow.title),
                      ),
                      const SizedBox(height: AppDimens.s04$xs),
                      Text(
                        subtitle,
                        style: AppFonts.caption(context)
                            .copyWith(color: flow.secondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.s08$sm),
                Switch.adaptive(
                  value: isOnline,
                  activeThumbColor: Colors.white,
                  activeTrackColor: flow.success,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: flow.secondary,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  onChanged: onChanged,
                ),
              ],
            ),
            if (!isOnline && explanation != null) ...[
              const SizedBox(height: AppDimens.s12$md),
              Text(
                explanation!,
                style: AppFonts.caption(context)
                    .copyWith(color: flow.secondary),
              ),
            ],
          ],
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 6,
              backgroundColor: isOnline ? Colors.green : Colors.grey,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            trailing: Switch.adaptive(
              value: isOnline,
              activeThumbColor: const Color(0xFF0F5A56),
              onChanged: onChanged,
            ),
          ),
          if (!isOnline && explanation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                explanation!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
