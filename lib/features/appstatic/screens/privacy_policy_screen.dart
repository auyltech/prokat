import 'package:flutter/material.dart';
import 'package:prokat/features/appstatic/screens/remote_legal_document_screen.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) => RemoteLegalDocumentScreen(
    slug: 'privacy-policy',
    title: AppLocalizations.of(context)!.privacyPolicy,
  );
}
