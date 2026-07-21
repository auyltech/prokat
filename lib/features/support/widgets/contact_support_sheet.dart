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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            l10n.contactSupport,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () {
              context.push(AppRoutes.contactSupport);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.email_outlined),
                  SizedBox(width: 12),
                  Text(
                    "Submit an Inquiry",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ListTile(
          //   leading: const Icon(Icons.chat_bubble_outline),
          //   title: Text(l10n.liveChat),
          //   onTap: () => context.push(AppRoutes.clientChatSupport),
          // ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
