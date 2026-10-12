import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

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
