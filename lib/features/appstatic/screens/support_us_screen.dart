import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_models.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

/// Hub for product feedback / demand survey. Opened from client and owner profiles.
class SupportUsScreen extends ConsumerStatefulWidget {
  const SupportUsScreen({super.key});

  @override
  ConsumerState<SupportUsScreen> createState() => _SupportUsScreenState();
}

class _SupportUsScreenState extends ConsumerState<SupportUsScreen> {
  bool _openingSurvey = false;

  Future<void> _openDemandSurvey() async {
    if (_openingSurvey) return;
    setState(() => _openingSurvey = true);

    final l10n = AppLocalizations.of(context)!;
    try {
      DemandConfig? config = ref.read(demandConfigProvider).valueOrNull;
      if (config == null || !config.shouldShow) {
        try {
          config = await ref.read(demandConfigProvider.future);
        } catch (_) {
          config = null;
        }
      }

      if (!mounted) return;

      final campaignId = config?.campaignId;
      if (campaignId == null ||
          campaignId.isEmpty ||
          !(config?.shouldShow ?? false)) {
        AppToast.show(
          message: l10n.demandSurveyLoadError,
          type: AppToastType.error,
        );
        return;
      }

      await context.push(AppRoutes.equipmentDemandPath(campaignId));
    } finally {
      if (mounted) setState(() => _openingSurvey = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.s24$xl),
          child: Center(
            child: AppElevatedButton(
              title: l10n.demandSurveyCardTitle,
              onTap: _openingSurvey ? null : _openDemandSurvey,
              isLoading: _openingSurvey,
            ),
          ),
        ),
      ),
    );
  }
}
