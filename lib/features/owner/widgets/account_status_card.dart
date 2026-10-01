import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/base_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class AccountStatusCard extends StatelessWidget {
  final bool online, changing, showHint;
  final ValueChanged<bool> onChanged;
  final String? title;
  final Color activeColor;
  const AccountStatusCard({
    super.key,
    required this.online,
    required this.changing,
    required this.onChanged,
    this.showHint = true,
    this.title,
    this.activeColor = const Color(0xFF0F5A56),
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BaseTile(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: CircleAvatar(
                radius: 6,
                backgroundColor: online ? Colors.green : Colors.grey,
              ),
              title: Text(
                title ?? (online ? l10n.youAreOnline : l10n.youAreOffline),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                online ? l10n.readyToAcceptOrders : l10n.notAcceptingOrders,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              trailing: Switch.adaptive(
                value: online,
                activeThumbColor: activeColor,
                onChanged: changing ? null : onChanged,
              ),
            ),
          ),
          if (!online && showHint)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l10n.ownerOfflineMustBeOnlineToAccept,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
