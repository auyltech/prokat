import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_outlined_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ContactSupportSheet extends StatelessWidget {
  const ContactSupportSheet({super.key});

  static void show(BuildContext context) {
    unawaited(
      showModalBottomSheet(
        context: context,
        builder: (context) => const ContactSupportSheet(),
      ),
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

          AppOutlinedButton(
            title: l10n.submitInquiry,
            onTap: () {
              unawaited(context.push(AppRoutes.contactSupport));
            },
            prefix: const Icon(Icons.email_outlined),
            isExpanded: true,
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
