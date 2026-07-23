import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/widgets/owner_profile_form.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerRegistrationScreen extends ConsumerStatefulWidget {
  const OwnerRegistrationScreen({super.key});

  @override
  ConsumerState<OwnerRegistrationScreen> createState() =>
      _OwnerRegistrationScreenState();
}

class _OwnerRegistrationScreenState
    extends ConsumerState<OwnerRegistrationScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final initialProfile = ref.watch(ownerRegistrationProvider).ownerProfile;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildStatusCard(
                //   theme,
                //   l10n,
                //   OwnerRegistrationStatus.incomplete,
                // ),
                if (initialProfile != null)
                  OwnerProfileForm(initialProfile: initialProfile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    AppLocalizations l10n,
    OwnerRegistrationStatus status,
  ) {
    String title;
    String subtitle;
    Color color;
    IconData icon;

    switch (status) {
      case OwnerRegistrationStatus.incomplete:
        title = l10n.completeRegistration;
        subtitle = l10n.submitDocumentsHint;
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;

      case OwnerRegistrationStatus.pending:
        title = l10n.verificationInProgress;
        subtitle = l10n.reviewingDocuments;
        color = Colors.blue;
        icon = Icons.hourglass_top;
        break;

      case OwnerRegistrationStatus.approved:
        title = l10n.youAreVerified;
        subtitle = l10n.canListEquipment;
        color = Colors.green;
        icon = Icons.verified;
        break;

      case OwnerRegistrationStatus.rejected:
        title = l10n.verificationFailed;
        subtitle = l10n.updateDocumentsHint;
        color = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
