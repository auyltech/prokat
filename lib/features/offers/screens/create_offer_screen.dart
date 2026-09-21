import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/error_box_tile.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/bookings/widgets/price_rate_selector.dart';
import 'package:prokat/features/billing/state/billing_provider.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/equipment/providers/owner_equipment_provider.dart';
import 'package:prokat/features/equipment/widgets/list/equipment_error_tile.dart';
import 'package:prokat/features/offers/offer_error_message.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/owner/owner_offline_guard.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _comment = TextEditingController();
  String? _submitError;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = ref.read(offerMutationProvider).selectedRequest;

      if (request == null) return;

      if (request.offeredPrice > 0) {
        _price.text = request.offeredPrice.toString();
        ref.read(offerMutationProvider.notifier).setPrice(request.offeredPrice);
      }
    });
  }

  @override
  void dispose() {
    _price.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final offersState = ref.watch(offerMutationProvider);
    final offersNotifier = ref.read(offerMutationProvider.notifier);
    final equipmentAsync = ref.watch(ownerEquipmentProvider);

    final equipmentOptions = (equipmentAsync.valueOrNull?.items ?? [])
        .map((item) => EquipmentSummaryModel.fromJson(item.toJson()))
        .toList();

    final canSubmit =
        offersState.priceRate != null &&
        offersState.selectedEquipment != null &&
        offersState.selectedRequest != null &&
        !ref.watch(offerMutationProvider).isSubmitting;

    Future<void> onSubmit() async {
      if (!(_formKey.currentState?.validate() ?? false)) {
        AppToast.show(
          message: l10n.pleaseProvideRequiredInformation,
          type: AppToastType.error,
        );
        return;
      }

      if (ref.read(billingProvider).isOutOfPaidMinutes) {
        AppToast.show(
          message: l10n.cannotRespondWithZeroBalance,
          type: AppToastType.error,
        );
        return;
      }

      if (!await ensureOwnerOnline(
        context,
        ref,
        message: l10n.ownerOfflineMustBeOnlineForTender,
      )) {
        return;
      }
      if (!context.mounted) return;

      setState(() => _submitError = null);

      offersNotifier.setPrice(parseNullableInt(_price.text) ?? 0);
      offersNotifier.setComment(_comment.text);

      final result = await offersNotifier.createOffer();
      if (!context.mounted) return;

      final message = result.success
          ? l10n.offerCreated
          : offerCreateErrorMessage(
              l10n: l10n,
              errorCode: result.errorCode,
              fallback: result.message,
            );

      AppToast.show(
        message: message,
        type: result.success ? AppToastType.success : AppToastType.error,
      );

      if (result.success) {
        context.pop();
        return;
      }

      setState(() => _submitError = message);
    }

    if (equipmentAsync.hasError && equipmentOptions.isEmpty) {
      return Scaffold(
        body: Center(
          child: EquipmentErrorTile(
            onRetry: () =>
                unawaited(ref.read(ownerEquipmentProvider.notifier).refresh()),
          ),
        ),
      );
    }

    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDropdownField<EquipmentSummaryModel>(
                title: l10n.navEquipment,
                hint: l10n.selectEquipment,
                sheetTitle: l10n.selectEquipment,
                value: offersState.selectedEquipment,
                options: equipmentOptions
                    .map(
                      (e) => DropdownOption(
                        value: e,
                        label: '${e.name}-${e.plateNumber}',
                      ),
                    )
                    .toList(),
                onChanged: offersNotifier.selectEquipment,
              ),

              const SizedBox(height: AppDimens.s16$base),

              AppTextField(
                title: l10n.priceKZT,
                controller: _price,
                hint: '12 000',
                isRequired: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: Text(
                  '₸',
                  style: AppFonts.body16SemiBold(context)
                      .copyWith(color: context.colors.text.secondary),
                ),
                validator: (v) => v == null || v.isEmpty ? l10n.required : null,
              ),

              const SizedBox(height: AppDimens.s16$base),

              SectionTitle(title: l10n.priceRateLabel),

              const SizedBox(height: AppDimens.s08$sm),

              PriceRateSelector(
                initialValue: ref.watch(offerMutationProvider).priceRate,
                onChanged: (val) =>
                    ref.read(offerMutationProvider.notifier).setPriceRate(val),
              ),

              const SizedBox(height: AppDimens.s16$base),

              AppTextArea(
                title: l10n.comments,
                controller: _comment,
                hint: l10n.equipmentNameHint,
                minLines: 2,
                maxLines: 4,
              ),

              const SizedBox(height: AppDimens.s24$xl),

              if (_submitError != null)
                ErrorBoxTile(errorMessage: _submitError),

              Row(
                children: [
                  Expanded(
                    child: AppElevatedButton(
                      title: l10n.sendOffer,
                      onTap: canSubmit ? onSubmit : null,
                      isLoading: offersState.isActionActive("offer:create"),
                      isExpanded: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
