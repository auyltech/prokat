import 'company_orders_screen.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_models.dart';
import 'company_service.dart';
import 'company_widgets.dart';

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});
  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bin = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bin.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(companyContextProvider);
    try {
      await ref.read(companyContextProvider.future);
    } catch (_) {
      /* shown in UI */
    }
  }

  Future<void> _apply() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(companyServiceProvider)
          .apply(name: _name.text, bin: _bin.text);
      _name.clear();
      _bin.clear();
      await _refresh();
      if (mounted) {
        companySnack(context, AppLocalizations.of(context)!.companyRequestSent);
      }
    } catch (error) {
      if (mounted) companySnack(context, companyErrorText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _accept(CompanyInvitation invitation) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(companyServiceProvider).acceptInvitation(invitation.id);
      await _refresh();
      if (mounted && invitation.organizationId.isNotEmpty) {
        context.go('/company-cabinet/${invitation.organizationId}/profile');
      }
    } catch (error) {
      if (mounted) companySnack(context, companyErrorText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _status(AppLocalizations l10n, String status) => switch (status) {
    'PENDING' => l10n.companyApplicationPending,
    'APPROVED' => l10n.companyApplicationApproved,
    'REJECTED' => l10n.companyApplicationRejected,
    _ => l10n.companyApplicationUnknown,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(companyContextProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyWorkspace)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: data.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CompanyOrdersScreen(),
                  ),
                ),
                icon: const Icon(LucideIcons.messageCircle400),
                label: Text(l10n.companyMyInquiries),
              ),
              CompanyNotice(l10n.companyLoadFailed),
              const SizedBox(height: 16),
              AppElevatedButton(title: l10n.retry, onTap: _refresh),
            ],
          ),
          data: (company) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              CompanyNotice(
                l10n.companyPersonalAccess,
                icon: LucideIcons.badgeCheck,
              ),
              const SizedBox(height: 20),
              for (final membership in company.memberships)
                CompanySection(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.building2, size: 32),
                    title: Text(membership.organization.name),
                    subtitle: Text(
                      membership.canManageProfile
                          ? l10n.companyManager
                          : l10n.companyDispatcher,
                    ),
                    trailing: const Icon(LucideIcons.chevronRight),
                    onTap: () async {
                      await context.push(
                        '/company-cabinet/${membership.organization.id}/profile',
                      );
                      if (mounted) await _refresh();
                    },
                  ),
                ),
              for (final invitation in company.invitations)
                CompanySection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.companyInvitation,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(invitation.companyName),
                      const SizedBox(height: 16),
                      AppElevatedButton(
                        title: l10n.companyAcceptInvitation,
                        onTap: _saving ? null : () => _accept(invitation),
                        isLoading: _saving,
                      ),
                    ],
                  ),
                ),
              for (final application in company.requests)
                CompanySection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _status(l10n, application.status),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${application.name}\n${l10n.companyBin}: ${application.bin}',
                      ),
                      if (application.adminComment.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        CompanyNotice(application.adminComment),
                      ],
                      if (application.isPending) ...[
                        const SizedBox(height: 12),
                        Text(l10n.companyPendingHint),
                      ],
                    ],
                  ),
                ),
              if (!company.hasPendingApplication && company.memberships.isEmpty)
                CompanySection(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.companyRegister,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.companyApplicationIntro),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: _name,
                          title: l10n.companyName,
                          maxLength: 100,
                          enabled: !_saving,
                          textInputAction: TextInputAction.next,
                          validator: (value) => (value?.trim().length ?? 0) < 2
                              ? l10n.companyNameInvalid
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _bin,
                          title: l10n.companyBin,
                          enabled: !_saving,
                          maxLength: 12,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) =>
                              RegExp(r'^\d{12}$').hasMatch(value?.trim() ?? '')
                              ? null
                              : l10n.companyBinInvalid,
                        ),
                        const SizedBox(height: 24),
                        AppElevatedButton(
                          title: l10n.companySubmitApplication,
                          onTap: _apply,
                          isLoading: _saving,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
