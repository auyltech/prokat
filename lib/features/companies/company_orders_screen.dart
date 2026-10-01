import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_order_state.dart';
import 'company_order_screen.dart' show CompanyOrderScreen;
import 'company_widgets.dart';

class CompanyOrdersScreen extends ConsumerStatefulWidget {
  final String? companyId;
  final Set<String>? statuses;
  final String? screenTitle;
  final bool chatsOnly;
  const CompanyOrdersScreen({
    super.key,
    this.companyId,
    this.statuses,
    this.screenTitle,
    this.chatsOnly = false,
  });
  @override
  ConsumerState<CompanyOrdersScreen> createState() =>
      _CompanyOrdersScreenState();
}

class _CompanyOrdersScreenState extends ConsumerState<CompanyOrdersScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _refreshing = false;
  String? get companyId => widget.companyId;
  Set<String>? get statuses => widget.statuses;
  String? get screenTitle => widget.screenTitle;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing ||
        !mounted ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    _refreshing = true;
    try {
      ref.invalidate(companyInquiryListProvider(companyId));
      await ref.read(companyInquiryListProvider(companyId).future);
    } catch (_) {
    } finally {
      _refreshing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _matches(Map<String, dynamic> item) =>
      (statuses == null || statuses!.contains(item['status'])) &&
      (!widget.chatsOnly || item['hasChat'] == true);
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          screenTitle ??
              (companyId == null ? l.companyMyInquiries : l.companyOrders),
          style: AppFonts.headingM(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(companyInquiryListProvider(companyId));
          await ref.read(companyInquiryListProvider(companyId).future);
        },
        child: ref
            .watch(companyInquiryListProvider(companyId))
            .when(
              skipLoadingOnRefresh: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  CompanyNotice(companyErrorText(context, e)),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(companyInquiryListProvider(companyId)),
                    child: Text(l.retry),
                  ),
                ],
              ),
              data: (items) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  if (items.where(_matches).isEmpty)
                    CompanyNotice(l.companyRequestEmpty),
                  for (final item in items.where(_matches))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CompanySection(
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${companyId == null ? item['companyName'] : item['clientName']}',
                            ),
                            subtitle: Text(
                              widget.chatsOnly
                                  ? '${item['lastMessage'] ?? companyOrderStatus(l, '${item['status']}')}'
                                  : '${companyOrderStatus(l, '${item['status']}')}\n${companyOrderDate(item['startsAt'])}',
                            ),
                            isThreeLine: !widget.chatsOnly,
                            trailing: const Icon(LucideIcons.chevronRight),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CompanyOrderScreen(id: '${item['id']}'),
                              ),
                            ),
                          ),
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
