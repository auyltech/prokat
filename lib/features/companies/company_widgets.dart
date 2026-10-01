import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/profile_accent_cta.dart';

import 'company_accent_border.dart';

import 'package:prokat/core/widgets/ui_kit/inputs/app_dropdown_field.dart';

import 'company_models.dart';
import 'company_service.dart';

class CompanyDropdownField<T> extends StatelessWidget {
  final String title;
  final T? value;
  final List<DropdownOption<T>> options;
  final ValueChanged<T>? onChanged;
  final FormFieldValidator<T>? validator;
  const CompanyDropdownField({
    super.key,
    required this.title,
    this.value,
    required this.options,
    this.onChanged,
    this.validator,
  });
  @override
  Widget build(BuildContext context) => FormField<T>(
    initialValue: value,
    validator: validator,
    builder: (field) => AppDropdownField<T>(
      title: title,
      sheetTitle: title,
      value: field.value,
      errorText: field.errorText,
      options: options,
      enabled: onChanged != null,
      isRequired: validator != null,
      onChanged: (next) {
        field.didChange(next);
        onChanged?.call(next);
        if (field.hasError) field.validate();
      },
    ),
  );
}

String companyRateSuffix(AppLocalizations l10n, String rate) => switch (rate) {
  'PER_HOUR' => l10n.perHour,
  'PER_DAY' => l10n.perDay,
  'PER_TRIP' => l10n.perTrip,
  'PER_CUBIC_METER' => l10n.perM3,
  _ => '',
};

String companyPriceText(AppLocalizations l10n, CompanyPrice price) {
  final suffix = companyRateSuffix(l10n, price.rate);
  return suffix.isEmpty ? '${price.amount}' : '${price.amount} $suffix';
}

String companyEquipmentStatus(AppLocalizations l10n, CompanyFleetItem item) =>
    switch (item.status) {
      'DRAFT' => item.busy ? l10n.companyBusy : l10n.companyFree,
      'CREATED' => l10n.companyReview,
      'REJECTED' => l10n.companyRejectedEquipment,
      'BOOKED' => l10n.companyBusy,
      'MAINTENANCE' => l10n.companyMaintenance,
      'AVAILABLE' =>
        item.isVisible ? l10n.equipmentShown : l10n.equipmentHidden,
      _ => l10n.companyStatusUnknown,
    };

class CompanyProfileTile extends ConsumerWidget {
  const CompanyProfileTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final data = ref.watch(companyContextProvider).valueOrNull;
    final memberships = data?.memberships ?? const [];
    final pending = data?.requests.where((item) => item.isPending).firstOrNull;
    final String title;
    final String subtitle;
    if (memberships.length == 1) {
      title = memberships.first.organization.name;
      subtitle = l10n.companyWorkspace;
    } else if (memberships.isNotEmpty) {
      title = l10n.companyWorkspace;
      subtitle = l10n.companyEntrySubtitle;
    } else if (pending != null) {
      title = pending.name;
      subtitle = l10n.companyApplicationPending;
    } else {
      title = l10n.companyRegister;
      subtitle = l10n.companyEntrySubtitle;
    }
    void enter() => context.push(
      memberships.length == 1
          ? '/company-cabinet/${memberships.first.organization.id}/profile'
          : AppRoutes.companies,
    );
    if (memberships.isNotEmpty) {
      return CompanyAccentBorder(
        child: ProfileAccentCta(
          title: title,
          subtitle: l10n.companyWorkspace,
          leading: const Icon(
            LucideIcons.building2,
            color: Colors.white,
            size: ProfileAccentCta.iconSize,
          ),
          verticalInset: 20,
          backgroundColor: Colors.transparent,
          onTap: enter,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ProkatListTile(
        icon: LucideIcons.building2,
        iconBgColor: colors.primary.withValues(alpha: .12),
        iconColor: colors.primary,
        title: title,
        subtitle: subtitle,
        onTap: enter,
      ),
    );
  }
}

class CompanyNotice extends StatelessWidget {
  final String text;
  final IconData icon;
  const CompanyNotice(this.text, {super.key, this.icon = LucideIcons.info});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class CompanySection extends StatelessWidget {
  final Widget child;
  const CompanySection({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

String companyErrorText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  if (error is CompanyApiException) {
    if ([400, 409].contains(error.statusCode) &&
        error.message?.isNotEmpty == true) {
      return error.message!;
    }
    if (error.statusCode == 409) return l10n.companyConflict;
    if (error.statusCode == 401 || error.statusCode == 403) {
      return l10n.companyAccessDenied;
    }
  }
  return l10n.companyActionFailed;
}

void companySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
