import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/constants/app_colors.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/widgets/owner_status_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerBusinessPreferencesSection extends ConsumerStatefulWidget {
  const OwnerBusinessPreferencesSection({super.key});

  @override
  ConsumerState<OwnerBusinessPreferencesSection> createState() =>
      _OwnerBusinessPreferencesSectionState();
}

class _OwnerBusinessPreferencesSectionState
    extends ConsumerState<OwnerBusinessPreferencesSection> {
  @override
  void initState() {
    super.initState();

    unawaited(Future.microtask(_loadBusinessData));
  }

  Future<void> _loadBusinessData() async {
    if (!mounted) return;

    // Always refresh so CHANGES_* / deadline from the latest admin decision show up.
    await ref.read(ownerProfileProvider.notifier).refresh();
    if (!mounted) return;

    if (ref.read(locationProvider).ownerLocations.isEmpty) {
      await ref.read(locationProvider.notifier).getOwnerLocations();
      if (!mounted) return;
    }

    if (ref.read(ownerEquipmentProvider).valueOrNull == null) {
      await ref.read(ownerEquipmentProvider.notifier).refresh();
    }
  }

  ({String? line, Color? color, IconData? icon}) _profileStatusFooter(
    OwnerProfileModel? profile,
    AppLocalizations l10n,
  ) {
    final status = effectiveOwnerBusinessStatus(
      status: profile?.status,
      isVerified: profile?.isVerified,
      ownerCycle: true,
    );
    if (status == OwnerRegistrationStatus.changesPending) {
      return (
        line: l10n.ownerProfileChangesPending,
        color: Colors.orange.shade800,
        icon: null,
      );
    }
    if (status == OwnerRegistrationStatus.changesRejected) {
      final overdue =
          profile?.isCorrectionOverdue == true ||
          (profile?.correctionDeadlineAt != null &&
              profile!.correctionDeadlineAt!.isBefore(DateTime.now()));
      if (overdue) {
        return (
          line: l10n.ownerProfileCorrectionOverdue,
          color: Colors.red.shade700,
          icon: LucideIcons.triangleAlert,
        );
      }
      final deadline = profile?.correctionDeadlineAt;
      final dateLabel = deadline == null
          ? null
          : formatDate(date: deadline.toLocal(), format: 'dd.MM.yyyy');
      return (
        line: dateLabel == null
            ? l10n.ownerProfileChangesRejected
            : '${l10n.ownerProfileChangesRejected} · ${l10n.ownerProfileChangesRejectedUntil(dateLabel)}',
        color: Colors.red.shade700,
        icon: null,
      );
    }
    return (line: null, color: null, icon: null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(ownerProfileProvider).valueOrNull;

    const accent = AppColors.teal800;
    final accentBackground = accent.withValues(alpha: 0.15);

    final businessName = (profile?.companyName ?? '').trim().isNotEmpty
        ? profile!.companyName!.trim()
        : profile?.ownerType == OwnerType.organization
        ? l10n.organization
        : l10n.individualOwner;

    final footer = _profileStatusFooter(profile, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OwnerStatusTile(),

        const SizedBox(height: 40),

        ProkatListTile(
          icon: LucideIcons.briefcase,
          iconColor: accent,
          iconBgColor: accentBackground,
          title: l10n.businessProfile,
          subtitle: businessName,
          statusLine: footer.line,
          statusColor: footer.color,
          statusIcon: footer.icon,
          onTap: () => context.push(AppRoutes.ownerRegistration),
        ),
      ],
    );
  }
}
