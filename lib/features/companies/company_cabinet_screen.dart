import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/layout/app_navigation_bar.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';

import 'company_profile_screen.dart';
import 'company_service.dart';
import 'company_widgets.dart';
import 'company_workspace_screen.dart';
import 'company_order_screen.dart';

class CompanyCabinetScreen extends ConsumerWidget {
  final String companyId;
  final String section;
  const CompanyCabinetScreen({
    super.key,
    required this.companyId,
    required this.section,
  });
  static const sections = ['profile', 'fleet', 'requests', 'orders', 'chats'];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final companies = ref.watch(companyContextProvider);
    final member = companies.valueOrNull?.memberships
        .where((m) => m.organization.id == companyId)
        .firstOrNull;
    final labels = [
      l.navProfile,
      l.navEquipment,
      l.navRequests,
      l.navOrders,
      l.navChats,
    ];
    final selected = sections.indexOf(section);
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: theme.brightness == Brightness.dark
              ? const Color(0xFFE6A6BA)
              : const Color(0xFF762E47),
        ),
      ),
      child: Scaffold(
        body: companies.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(companyContextProvider),
              child: Text(l.retry),
            ),
          ),
          data: (_) {
            if (member == null)
              return Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.clientProfile),
                  child: Text(l.companyAccessDenied),
                ),
              );
            if (section == 'fleet')
              return CompanyWorkspaceScreen(companyId: companyId);
            if (section != 'profile')
              return CompanyOrdersScreen(
                companyId: companyId,
                screenTitle: labels[selected < 0 ? 0 : selected],
                statuses: section == 'requests'
                    ? {'NEW', 'PROPOSED'}
                    : section == 'orders'
                    ? {'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'}
                    : null,
              );
            return CompanyProfileScreen(
              membership: member,
              onInvite: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _InviteDispatcher(companyId: companyId),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: member == null
            ? null
            : AppNavigationBar(
                tone: AppNavigationBarTone.company,
                currentIndex: selected < 0 ? 0 : selected,
                items: [
                  for (var i = 0; i < labels.length; i++)
                    AppNavigationBarItem(
                      icon: [
                        LucideIcons.user2400,
                        LucideIcons.truck400,
                        LucideIcons.radar400,
                        LucideIcons.scrollText400,
                        LucideIcons.messageCircle400,
                      ][i],
                      label: labels[i],
                    ),
                ],
                onItemTap: (i) =>
                    context.go('/company-cabinet/$companyId/${sections[i]}'),
              ),
      ),
    );
  }
}

class _InviteDispatcher extends ConsumerStatefulWidget {
  final String companyId;
  const _InviteDispatcher({required this.companyId});
  @override
  ConsumerState<_InviteDispatcher> createState() => _InviteDispatcherState();
}

class _InviteDispatcherState extends ConsumerState<_InviteDispatcher> {
  final phone = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.companyInviteDispatcher)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppTextField(
              controller: phone,
              title: l.companyPhone,
              hint: '+7…',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            AppElevatedButton(
              title: l.companyInviteDispatcher,
              isLoading: saving,
              onTap: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(companyServiceProvider)
                            .inviteDispatcher(widget.companyId, phone.text);
                        if (context.mounted) {
                          companySnack(context, l.companyInvitationSent);
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (context.mounted)
                          companySnack(context, companyErrorText(context, e));
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
