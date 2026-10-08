import 'package:flutter/material.dart';
import 'package:prokat/features/appstatic/screens/remote_legal_document_screen.dart';
import 'package:prokat/l10n/app_localizations.dart';

class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});
  @override
  Widget build(BuildContext context) => RemoteLegalDocumentScreen(
    slug: 'user-agreement',
    title: AppLocalizations.of(context)!.userAgreement,
  );
}
