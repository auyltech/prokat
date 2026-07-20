import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ContactSupportSheet extends StatelessWidget {
  const ContactSupportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ContactSupportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.contactSupport,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text("Submit an Inquiry"),
            onTap: () {
              context.push(AppRoutes.contactSupport);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(l10n.liveChat),
            onTap: () => context.push(AppRoutes.clientChatSupport),
          ),
        ],
      ),
    );
  }
}
