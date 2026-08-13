import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'equipment_demand_models.dart';
import 'equipment_demand_provider.dart';

class EquipmentDemandScreen extends ConsumerStatefulWidget {
  final String campaignId;
  const EquipmentDemandScreen({super.key, required this.campaignId});

  @override
  ConsumerState<EquipmentDemandScreen> createState() =>
      _EquipmentDemandScreenState();
}

class _EquipmentDemandScreenState extends ConsumerState<EquipmentDemandScreen> {
  final _otherController = TextEditingController();
  final _submissionId = const Uuid().v4();
  final Set<String> _selected = {};
  String? _city;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final currentCity = ref.read(locationProvider).city;
    if (cities.contains(currentCity)) _city = currentCity;
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final other = _otherController.text.trim();
    if (!cities.contains(_city) || (_selected.isEmpty && other.isEmpty)) {
      setState(() => _error = l10n.demandSurveySubmitError);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(equipmentDemandServiceProvider)
          .submit(
            clientSubmissionId: _submissionId,
            campaignId: widget.campaignId,
            city: _city!,
            optionIds: _selected.toList()..sort(),
            otherText: other.isEmpty ? null : other,
          );
      ref.read(demandConfigProvider.notifier).markResponded(widget.campaignId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.demandSurveyThankYou)));
      context.pop();
    } on DemandApiException catch (error) {
      if (error.code == 'DEMAND_RESPONSE_ALREADY_EXISTS') {
        ref
            .read(demandConfigProvider.notifier)
            .markResponded(widget.campaignId);
        if (mounted) context.pop();
        return;
      }
      if (error.code == 'DEMAND_CAMPAIGN_INACTIVE') {
        await ref.read(demandConfigProvider.notifier).refresh();
        if (mounted) context.pop();
        return;
      }
      if (mounted) setState(() => _error = l10n.demandSurveySubmitError);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.demandSurveySubmitError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(demandFormProvider(widget.campaignId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.demandSurveyCardTitle)),
      body: form.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.demandSurveyLoadError),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(demandFormProvider(widget.campaignId)),
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.demandSurveyQuestionTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(l10n.demandSurveyQuestionSubtitle),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: InputDecoration(
                labelText: l10n.demandSurveyCityLabel,
                border: const OutlineInputBorder(),
              ),
              hint: Text(l10n.demandSurveySelectCity),
              items: cities
                  .map(
                    (city) => DropdownMenuItem(value: city, child: Text(city)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 20),
            ...data.options.map(
              (option) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selected.contains(option.id),
                title: Text(option.name),
                onChanged: (checked) => setState(() {
                  checked == true
                      ? _selected.add(option.id)
                      : _selected.remove(option.id);
                }),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otherController,
              maxLength: 500,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.demandSurveyOtherOption,
                hintText: l10n.demandSurveyOtherHint,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.demandSurveySubmit),
            ),
          ],
        ),
      ),
    );
  }
}
