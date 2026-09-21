import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_option_card.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_survey_app_bar.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_survey_city_field.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_survey_comment_field.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
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
  bool _otherSelected = false;
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

  Future<void> _submit(DemandForm data) async {
    final l10n = AppLocalizations.of(context)!;
    final other = _otherController.text.trim();
    final catalog = ref.read(catalogProvider).valueOrNull;
    final cityKeys = catalogCityKeys(catalog);
    final otherText = data.allowOther && _otherSelected && other.isNotEmpty
        ? other
        : null;
    if (canonicalCity(_city, cityKeys) == null ||
        (_selected.isEmpty && otherText == null)) {
      setState(() => _error = l10n.demandSurveySubmitError);
      return;
    }
    if (data.allowOther && _otherSelected && other.isEmpty) {
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
            otherText: otherText,
          );
      ref.read(demandConfigProvider.notifier).markResponded(widget.campaignId);
      if (!mounted) return;
      AppToast.show(
        message: l10n.demandSurveyThankYou,
        type: AppToastType.success,
      );
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
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final form = ref.watch(demandFormProvider(widget.campaignId));
    return Scaffold(
      appBar: DemandSurveyAppBar(title: l10n.demandSurveyCardTitle),
      body: form.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.s24$xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.demandSurveyLoadError,
                  style: AppFonts.body14(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimens.s12$md),
                AppIconButton(
                  icon: Icons.refresh,
                  onTap: () =>
                      ref.invalidate(demandFormProvider(widget.campaignId)),
                  variant: AppIconButtonVariant.filled,
                  tone: AppIconButtonTone.primary,
                ),
              ],
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppDimens.s20$lg),
          children: [
            Text(
              l10n.demandSurveyQuestionTitle,
              style: AppFonts.headingM(context),
            ),
            const SizedBox(height: AppDimens.s08$sm),
            Text(
              l10n.demandSurveyQuestionSubtitle,
              style: AppFonts.caption(context),
            ),
            const SizedBox(height: AppDimens.s24$xl),
            DemandSurveyCityField(city: _city, onTap: _pickCity),
            const SizedBox(height: AppDimens.s20$lg),
            ...data.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.s12$md),
                child: DemandOptionCard(
                  title: option.name,
                  description: option.description,
                  imageUrl: option.imageUrl,
                  selected: _selected.contains(option.id),
                  onTap: () => setState(() {
                    if (_selected.contains(option.id)) {
                      _selected.remove(option.id);
                    } else {
                      _selected.add(option.id);
                    }
                  }),
                ),
              ),
            ),
            if (data.allowOther) ...[
              DemandOptionCard(
                title: data.other?.name ?? l10n.demandSurveyOtherOption,
                imageUrl: data.other?.imageUrl,
                selected: _otherSelected,
                onTap: () => setState(() {
                  _otherSelected = !_otherSelected;
                  if (!_otherSelected) _otherController.clear();
                }),
              ),
              if (_otherSelected) ...[
                const SizedBox(height: AppDimens.s12$md),
                DemandSurveyCommentField(controller: _otherController),
              ],
            ],
            const SizedBox(height: AppDimens.s24$xl),
            if (_error != null)
              Text(
                _error!,
                style: AppFonts.caption(context).copyWith(
                  color: colors.text.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: AppDimens.s24$xl),
            AppElevatedButton(
              title: l10n.demandSurveySubmit,
              onTap: _submitting ? null : () => _submit(data),
              isLoading: _submitting,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }
}
