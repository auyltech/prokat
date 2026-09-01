import 'dart:async';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(ownerProfileProvider.notifier).refreshIfStale());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final initialProfile = ref.watch(ownerProfileProvider).valueOrNull;
    final status = initialProfile?.status;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(ownerProfileProvider.notifier).refresh();
        },
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status != null &&
                      shouldShowOwnerProfileStatusBanner(status))
                    _buildStatusCard(l10n, status),
                  if (initialProfile != null)
                    OwnerProfileForm(initialProfile: initialProfile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    AppLocalizations l10n,
    OwnerRegistrationStatus status,
  ) {
    final (title, subtitle, color, icon) = switch (status) {
      OwnerRegistrationStatus.pending => (
        l10n.ownerProfilePendingReview,
        l10n.ownerProfilePendingReviewHint,
        Colors.blue,
        Icons.hourglass_top,
      ),
      OwnerRegistrationStatus.rejected => (
        l10n.verificationFailed,
        l10n.statusRejectedSubtitle,
        Colors.red,
        Icons.error_outline,
      ),
      OwnerRegistrationStatus.suspended => (
        l10n.ownerProfileSuspended,
        l10n.ownerProfileSuspendedHint,
        Colors.red,
        Icons.block,
      ),
      OwnerRegistrationStatus.incomplete || OwnerRegistrationStatus.approved =>
        ('', '', Colors.transparent, Icons.info_outline),
    };

    if (title.isEmpty) return const SizedBox.shrink();

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
