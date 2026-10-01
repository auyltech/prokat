import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_outlined_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/theme/app_fonts.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';

import 'company_service.dart';
import 'company_widgets.dart';

import 'company_order_state.dart';
export 'company_order_state.dart';

String _messageId() {
  final r = Random.secure();
  final bytes = List.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class CompanyOrderScreen extends ConsumerStatefulWidget {
  final String id;
  const CompanyOrderScreen({super.key, required this.id});
  @override
  ConsumerState<CompanyOrderScreen> createState() => _CompanyOrderScreenState();
}

class _CompanyOrderScreenState extends ConsumerState<CompanyOrderScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _timer;
  bool _busy = false, _polling = false, _foreground = true;
  String? _sendId, _lastContent;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_polling ||
        _busy ||
        !mounted ||
        !_foreground ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    _polling = true;
    try {
      ref.invalidate(companyInquiryProvider(widget.id));
      await ref.read(companyInquiryProvider(widget.id).future);
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  Future<void> _act(
    String action,
    Map<String, dynamic> body, {
    bool clear = false,
  }) async {
    if (_busy) return;
    final company = ref
        .read(companyInquiryProvider(widget.id))
        .valueOrNull?['company'];
    setState(() => _busy = true);
    try {
      await ref
          .read(companyServiceProvider)
          .inquiryAction(widget.id, action, body);
      if (clear) {
        _text.clear();
        _sendId = null;
      }
      ref.invalidate(companyInquiryProvider(widget.id));
      ref.invalidate(companyInquiryListProvider);
      if (company is Map && company['id'] is String) {
        ref.invalidate(companyFleetProvider(company['id'] as String));
        ref.invalidate(companyBillingProvider(company['id'] as String));
      }
    } catch (e) {
      if (mounted) companySnack(context, companyErrorText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(
    String action,
    String label,
    Map<String, dynamic> order,
  ) async {
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(l.companyActionConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await _act(action, {'version': order['version']});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.companyOrderTitle, style: AppFonts.headingM(context)),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: l.retry,
          ),
        ],
      ),
      body: ref
          .watch(companyInquiryProvider(widget.id))
          .when(
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CompanyNotice(companyErrorText(context, e)),
                  TextButton(onPressed: _refresh, child: Text(l.retry)),
                ],
              ),
            ),
            data: (order) {
              final side = order['companySide'] == true;
              final status = '${order['status']}';
              final company = Map<String, dynamic>.from(
                order['company'] as Map,
              );
              final messages = (order['messages'] as List)
                  .whereType<Map>()
                  .toList();
              final active = [
                'NEW',
                'PROPOSED',
                'CONFIRMED',
                'IN_PROGRESS',
              ].contains(status);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        CompanySection(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${company['name']}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                companyOrderStatus(l, status),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${companyOrderDate(order['startsAt'])}${order['endsAt'] == null ? '' : ' — ${companyOrderDate(order['endsAt'])}'}',
                              ),
                              if (order['comment'] != null) ...[
                                const SizedBox(height: 8),
                                Text('${order['comment']}'),
                              ],
                              if (order['budget'] != null)
                                Text(
                                  '${l.companyBudget}: ${order['budget']} ₸',
                                ),
                              for (final machine
                                  in (order['assignedMachines'] as List? ?? []))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.truck400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${machine['name']} · ${machine['model']}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (order['agreedPrice'] != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '${order['agreedPrice']} ₸ · ${l.companyWholeOrder}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (side && ['NEW', 'PROPOSED'].contains(status))
                                AppElevatedButton(
                                  title: l.companyProposeTerms,
                                  onTap: () async {
                                    final saved = await Navigator.of(context)
                                        .push<bool>(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CompanyProposalScreen(
                                                  order: order,
                                                ),
                                          ),
                                        );
                                    if (saved == true && mounted) {
                                      await _refresh();
                                    }
                                  },
                                ),
                              if (!side && status == 'PROPOSED')
                                AppElevatedButton(
                                  title: l.companyConfirmTerms,
                                  onTap: _busy
                                      ? null
                                      : () => _confirm(
                                          'confirm',
                                          l.companyConfirmTerms,
                                          order,
                                        ),
                                ),
                              if (side && status == 'CONFIRMED')
                                AppElevatedButton(
                                  title: l.companyStartWork,
                                  onTap: _busy
                                      ? null
                                      : () => _confirm(
                                          'start',
                                          l.companyStartWork,
                                          order,
                                        ),
                                ),
                              if (side && status == 'IN_PROGRESS')
                                AppElevatedButton(
                                  title: l.companyCompleteOrder,
                                  onTap: _busy
                                      ? null
                                      : () => _confirm(
                                          'complete',
                                          l.companyCompleteOrder,
                                          order,
                                        ),
                                ),
                              if (active)
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _confirm(
                                          'cancel',
                                          l.companyCancelOrder,
                                          order,
                                        ),
                                  child: Text(
                                    l.companyCancelOrder,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l.companyOrderChat,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (messages.isEmpty)
                          CompanyNotice(l.companyDiscussFirst),
                        for (final m in messages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: m['system'] == true
                                ? Center(
                                    child: Text(
                                      '${m['content'] ?? ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  )
                                : Align(
                                    alignment:
                                        (m['fromCompany'] == true) == side
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                            0.8,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            (m['fromCompany'] == true) == side
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer
                                            : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m['fromCompany'] == true
                                                ? '${company['name']}'
                                                : '${order['clientName']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text('${m['content'] ?? ''}'),
                                          const SizedBox(height: 4),
                                          Text(
                                            companyOrderDate(m['createdAt']),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        if (!active) CompanyNotice(l.companyReadOnlyChat),
                      ],
                    ),
                  ),
                  if (active)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _text,
                                enabled: !_busy,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 2000,
                                decoration: InputDecoration(
                                  hintText: l.companyMessageHint,
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      final content = _text.text.trim();
                                      if (content.isEmpty) return;
                                      if (_lastContent != content ||
                                          _sendId == null) {
                                        _sendId = _messageId();
                                        _lastContent = content;
                                      }
                                      unawaited(
                                        _act('messages', {
                                          'content': content,
                                          'clientTempId': _sendId,
                                        }, clear: true),
                                      );
                                    },
                              tooltip: l.companySendMessage,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(LucideIcons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }
}

class CompanyProposalScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> order;
  const CompanyProposalScreen({super.key, required this.order});
  @override
  ConsumerState<CompanyProposalScreen> createState() =>
      _CompanyProposalScreenState();
}

class _CompanyProposalScreenState extends ConsumerState<CompanyProposalScreen> {
  late final _start = DateTime.parse('${widget.order['startsAt']}').toLocal();
  late DateTime _from = _start;
  late DateTime _end = widget.order['endsAt'] == null
      ? _start.add(const Duration(hours: 1))
      : DateTime.parse('${widget.order['endsAt']}').toLocal();
  late final _ids = Set<String>.from(
    (widget.order['assignedEquipmentIds'] as List).isNotEmpty
        ? widget.order['assignedEquipmentIds'] as List
        : widget.order['equipmentIds'] as List,
  );
  late final _price = TextEditingController(
    text: '${widget.order['agreedPrice'] ?? widget.order['budget'] ?? ''}',
  );
  bool _saving = false;
  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _time(bool end) async {
    final current = end ? _end : _from;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(now) ? now : current,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 366)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time != null && mounted) {
      setState(() {
        final d = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (end) {
          _end = d;
        } else {
          _from = d;
        }
      });
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final amount = int.tryParse(_price.text.trim());
    if (_ids.isEmpty) {
      companySnack(context, l.companySelectFleet);
      return;
    }
    if (amount == null || amount < 0 || amount > 100000000) {
      companySnack(context, l.companyAmountInvalid);
      return;
    }
    if (!_from.isAfter(DateTime.now()) || !_end.isAfter(_from)) {
      companySnack(context, l.companyPeriodInvalid);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(companyServiceProvider).inquiryAction(
        '${widget.order['id']}',
        'propose',
        {
          'version': widget.order['version'],
          'equipmentIds': _ids.toList(),
          'price': amount,
          'startsAt': _from.toUtc().toIso8601String(),
          'endsAt': _end.toUtc().toIso8601String(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) companySnack(context, companyErrorText(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final company = widget.order['company'] as Map;
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.companyProposeTerms, style: AppFonts.headingM(context)),
      ),
      body: ref
          .watch(companyFleetProvider('${company['id']}'))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Padding(
              padding: const EdgeInsets.all(20),
              child: CompanyNotice(companyErrorText(context, e)),
            ),
            data: (fleet) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                CompanyNotice(l.companyDiscussFirst),
                const SizedBox(height: 16),
                for (final group in fleet.groups) ...[
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final category in group.categories) ...[
                    Text(
                      category.label(locale),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final machine in category.items.where(
                      (m) => m.status != 'ARCHIVED',
                    ))
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(machine.name),
                        subtitle: Text(machine.model),
                        value: _ids.contains(machine.id),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  _ids.add(machine.id);
                                } else {
                                  _ids.remove(machine.id);
                                }
                              }),
                      ),
                  ],
                ],
                const SizedBox(height: 16),
                AppOutlinedButton(
                  onTap: _saving ? null : () => _time(false),
                  title: '${l.companyStartTime}: ${companyOrderDate(_from)}',
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  onTap: _saving ? null : () => _time(true),
                  title: '${l.companyEndTime}: ${companyOrderDate(_end)}',
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _price,
                  title: l.companyTotalPrice,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 20),
                AppElevatedButton(
                  title: l.companySendTerms,
                  onTap: _saving ? null : _save,
                  isLoading: _saving,
                ),
              ],
            ),
          ),
    );
  }
}
