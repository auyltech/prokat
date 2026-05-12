import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/primary_button.dart';

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

    return Scaffold(
      // appBar: AppBar(title: const Text("Owner Verification")),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  "Owner Profile",
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(theme),

                const SizedBox(height: 16),

                _sectionTitle("Legal Information", theme),
                _card([
                  _tile("Full Name", "", () {}),
                  _tile("Address", "", () {}),
                  _tile("Phone Number", "", () {}),
                ]),

                const SizedBox(height: 16),

                _sectionTitle("Documents", theme),
                _card([
                  _documentTile("ID / Passport", true, () {}),
                  _documentTile("Proof of Address", false, () {}),
                  _documentTile("Business License (optional)", false, () {}),
                ]),

                const SizedBox(height: 16),

                _buildCTA(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 STATUS CARD (core UX)
  Widget _buildStatusCard(ThemeData theme) {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    switch (status) {
      case OwnerVerificationStatus.incomplete:
        title = "Complete your registration";
        subtitle = "Submit required documents to start listing equipment.";
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;

      case OwnerVerificationStatus.pending:
        title = "Verification in progress";
        subtitle = "We are reviewing your documents.";
        color = Colors.blue;
        icon = Icons.hourglass_top;
        break;

      case OwnerVerificationStatus.approved:
        title = "You're verified 🎉";
        subtitle = "You can now list and rent out equipment.";
        color = Colors.green;
        icon = Icons.verified;
        break;

      case OwnerVerificationStatus.rejected:
        title = "Verification failed";
        subtitle = "Please update your documents and try again.";
        color = Colors.red;
        icon = Icons.error_outline;
        break;

      default:
        title = "Complete your registration";
        subtitle = "Submit required documents to start listing equipment.";
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

  /// 📄 DOCUMENT TILE
  Widget _documentTile(String title, bool uploaded, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(uploaded ? "Uploaded" : "Required"),
      trailing: Icon(
        uploaded ? Icons.check_circle : Icons.upload_file,
        color: uploaded ? Colors.green : null,
      ),
      onTap: onTap,
    );
  }

  /// 🔧 GENERAL TILE
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

  /// 🚀 CTA BUTTON (dynamic)
  Widget _buildCTA(BuildContext context) {
    String text;

    switch (status) {
      case OwnerVerificationStatus.incomplete:
        text = "Submit for Verification";
        break;
      case OwnerVerificationStatus.pending:
        text = "Under Review";
        break;
      case OwnerVerificationStatus.approved:
        text = "View Listings";
        break;
      case OwnerVerificationStatus.rejected:
        text = "Resubmit Documents";
        break;
      default:
        text = "Submit for Verification";
        break;
    }

    return PrimaryButton(
      label: text,
      onPressed: status == OwnerVerificationStatus.pending ? null : () {},
    );
  }
}
