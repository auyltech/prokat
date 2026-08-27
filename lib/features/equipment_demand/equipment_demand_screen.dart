import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_survey_app_bar.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_survey_city_field.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_survey_comment_field.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../core/widgets/action_button.dart';
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
    final catalog = ref.read(catalogProvider).valueOrNull;
    _city = canonicalCity(currentCity, catalogCityKeys(catalog));
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final other = _otherController.text.trim();
    final catalog = ref.read(catalogProvider).valueOrNull;
    final cityKeys = catalogCityKeys(catalog);
    if (canonicalCity(_city, cityKeys) == null ||
        (_selected.isEmpty && other.isEmpty)) {
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

  Future<void> _pickCity() async {
    final selected = await CityPickerSheet.show(
      context: context,
      service: CitySelectorService.demandsurvey,
    );
    if (!mounted || selected == null || selected.isEmpty) return;
    setState(() {
      final catalog = ref.read(catalogProvider).valueOrNull;
      _city = canonicalCity(selected, catalogCityKeys(catalog)) ?? selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(demandFormProvider(widget.campaignId));
    return Scaffold(
      appBar: DemandSurveyAppBar(title: l10n.demandSurveyCardTitle),
      body: form.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.demandSurveyLoadError,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
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
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.demandSurveyQuestionSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            DemandSurveyCityField(city: _city, onTap: _pickCity),
            const SizedBox(height: 20),
            ...data.options.map(
              (option) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selected.contains(option.id),
                checkColor: Colors.white,
                title: Text(option.name, style: theme.textTheme.bodyMedium),
                onChanged: (checked) => setState(() {
                  checked == true
                      ? _selected.add(option.id)
                      : _selected.remove(option.id);
                }),
              ),
            ),
            const SizedBox(height: 12),
            DemandSurveyCommentField(controller: _otherController),

            const SizedBox(height: 24),

            if (_error != null)
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 24),
            ActionButton(
              label: l10n.demandSurveySubmit,
              onPressed: _submitting ? null : _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}
