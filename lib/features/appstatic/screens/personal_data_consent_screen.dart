import 'package:flutter/material.dart';
import 'package:prokat/features/appstatic/screens/remote_legal_document_screen.dart';
import 'package:prokat/l10n/app_localizations.dart';

class PersonalDataConsentScreen extends StatelessWidget {
  const PersonalDataConsentScreen({super.key});
  @override
  Widget build(BuildContext context) => RemoteLegalDocumentScreen(
    slug: 'consent',
    title: AppLocalizations.of(context)!.userConsent,
  );
}
