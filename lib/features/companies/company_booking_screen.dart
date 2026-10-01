import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_outlined_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_service.dart';
import 'company_widgets.dart';
import 'company_order_screen.dart';

class CompanyBookingScreen extends ConsumerStatefulWidget {
  final String companyId;
  const CompanyBookingScreen({super.key, required this.companyId});

  @override
  ConsumerState<CompanyBookingScreen> createState() =>
      _CompanyBookingScreenState();
}

class _CompanyBookingScreenState extends ConsumerState<CompanyBookingScreen> {
  final _form = GlobalKey<FormState>();
  final _comment = TextEditingController();
  final _budget = TextEditingController();
  DateTime? _when;
  bool _saving = false;
  bool _attempted = false;

  @override
  void dispose() {
    _comment.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _when ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _when ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null || !mounted) return;
    setState(
      () => _when = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _send() async {
    setState(() => _attempted = true);
    if (_saving ||
        !(_form.currentState?.validate() ?? false) ||
        _when == null) {
      return;
    }
    if (!_when!.isAfter(DateTime.now())) {
      companySnack(
        context,
        AppLocalizations.of(context)!.companyFutureDateRequired,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final selected = ref.read(companySelectionProvider(widget.companyId));
      final budgetText = _budget.text.trim();
      final requestId = await ref
          .read(companyServiceProvider)
          .sendBookingRequest(
            widget.companyId,
            equipmentIds: selected.toList(),
            startsAt: _when!,
            comment: _comment.text,
            budget: budgetText.isEmpty ? null : int.parse(budgetText),
          );
      ref.read(companySelectionProvider(widget.companyId).notifier).state =
          <String>{};
      if (mounted) {
        companySnack(
          context,
          AppLocalizations.of(context)!.companyBookingRequestSent,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => CompanyOrderScreen(id: requestId)),
        );
      }
    } catch (error) {
      if (mounted) companySnack(context, companyErrorText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(companySelectionProvider(widget.companyId));
    final whenLabel = _when == null
        ? l10n.companyWhen
        : '${_when!.day.toString().padLeft(2, '0')}.${_when!.month.toString().padLeft(2, '0')}.${_when!.year} ${_when!.hour.toString().padLeft(2, '0')}:${_when!.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.companySendRequest)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            CompanyNotice(l10n.companyRequestChatFirst),
            const SizedBox(height: 16),
            Text(l10n.companySelected(selected.length)),
            const SizedBox(height: 16),
            AppOutlinedButton(
              onTap: _saving ? null : _pickDate,
              title: whenLabel,
            ),
            if (_attempted && _when == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.companyFieldRequired,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _budget,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final amount = int.tryParse(text);
                return amount == null || amount < 0 || amount > 100000000
                    ? l10n.companyAmountInvalid
                    : null;
              },
              title: l10n.companyBudget,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_saving,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _comment,
              title: l10n.companyBookingComment,
              maxLength: 250,
              maxLines: 4,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            AppElevatedButton(
              title: l10n.companySendRequest,
              onTap: _send,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
