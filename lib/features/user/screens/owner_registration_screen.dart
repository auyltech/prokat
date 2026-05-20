import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

enum OwnerVerificationStatus { incomplete, pending, approved, rejected }

class OwnerRegistrationScreen extends StatelessWidget {
  final OwnerVerificationStatus? status;

  const OwnerRegistrationScreen({
    super.key,
    this.status = OwnerVerificationStatus.incomplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.ownerProfile,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.push(AppRoutes.ownerDashboard),
        ),
        backgroundColor: AppColors.teal700,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(theme, l10n),

                const SizedBox(height: 16),

                _sectionTitle(l10n.legalInformation, theme),
                _card([
                  _tile(l10n.fullName, "", () {}),
                  _tile(l10n.address, "", () {}),
                  _tile(l10n.phoneNumber, "", () {}),
                ]),

                const SizedBox(height: 16),

                _sectionTitle(l10n.documents, theme),
                _card([
                  _documentTile(l10n.idPassport, true, l10n, () {}),
                  _documentTile(l10n.proofOfAddress, false, l10n, () {}),
                  _documentTile(l10n.businessLicense, false, l10n, () {}),
                ]),

                const SizedBox(height: 16),

                _buildCTA(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, AppLocalizations l10n) {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    switch (status) {
      case OwnerVerificationStatus.incomplete:
        title = l10n.completeRegistration;
        subtitle = l10n.submitDocumentsHint;
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;

      case OwnerVerificationStatus.pending:
        title = l10n.verificationInProgress;
        subtitle = l10n.reviewingDocuments;
        color = Colors.blue;
        icon = Icons.hourglass_top;
        break;

      case OwnerVerificationStatus.approved:
        title = l10n.youAreVerified;
        subtitle = l10n.canListEquipment;
        color = Colors.green;
        icon = Icons.verified;
        break;

      case OwnerVerificationStatus.rejected:
        title = l10n.verificationFailed;
        subtitle = l10n.updateDocumentsHint;
        color = Colors.red;
        icon = Icons.error_outline;
        break;

      default:
        title = l10n.completeRegistration;
        subtitle = l10n.submitDocumentsHint;
        color = Colors.orange;
        icon = Icons.pending_actions;
    }

    return Card(
      color: theme.colorScheme.surfaceBright,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _documentTile(
    String title,
    bool uploaded,
    AppLocalizations l10n,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(uploaded ? l10n.uploaded : l10n.requiredDoc),
      trailing: Icon(
        uploaded ? Icons.check_circle : Icons.upload_file,
        color: uploaded ? Colors.green : null,
      ),
      onTap: onTap,
    );
  }

  Widget _tile(String title, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(title, style: theme.textTheme.titleMedium);
  }

  Widget _card(List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _buildCTA(BuildContext context, AppLocalizations l10n) {
    String text;

    switch (status) {
      case OwnerVerificationStatus.incomplete:
        text = l10n.submitForVerification;
        break;
      case OwnerVerificationStatus.pending:
        text = l10n.underReview;
        break;
      case OwnerVerificationStatus.approved:
        text = l10n.viewListings;
        break;
      case OwnerVerificationStatus.rejected:
        text = l10n.resubmitDocuments;
        break;
      default:
        text = l10n.submitForVerification;
        break;
    }

    return PrimaryButton(
      label: text,
      onPressed: status == OwnerVerificationStatus.pending ? null : () {},
    );
  }
}
