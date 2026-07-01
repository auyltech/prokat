import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_picker_component.dart';
import 'package:prokat/core/widgets/drowp_down_field.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/core/widgets/time_picker_component.dart';
import 'package:prokat/features/bookings/widgets/price_rate_selector.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/equipment/state/equipment_provider.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/widgets/input_field.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  const CreateOfferScreen({super.key});

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _comment = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = ref.read(offersProvider).selectedRequest;

      if (request == null) return;

      // Price
      _price.text = request.offeredPrice.toString();
      ref.read(offersProvider.notifier).setPrice(request.offeredPrice);

      // Date
      if (request.requiredOn != null) {
        ref.read(offersProvider.notifier).setDate(request.requiredOn!);
      }

      // Time
      if (request.requiredAt != null) {
        ref.read(offersProvider.notifier).setTime(request.requiredAt!);
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

    final offersState = ref.watch(offersProvider);
    final offersNotifier = ref.read(offersProvider.notifier);
    final equipmentState = ref.watch(equipmentProvider);

    final equipmentOptions = equipmentState.ownerEquipment
        .map((item) => EquipmentSummaryModel.fromJson(item.toJson()))
        .toList();

    final canSubmit =
        offersState.priceRate != null &&
        offersState.selectedEquipment != null &&
        offersState.selectedRequest != null &&
        !ref.watch(offersProvider).isSubmitting;

    Future<void> onSubmit() async {
      if (_formKey.currentState?.validate() ?? false) {
        offersNotifier.setPrice(parseNullableInt(_price.text) ?? 0);
        offersNotifier.setComment(_comment.text);

        final result = await offersNotifier.createOffer();

        if (result.success && context.mounted) {
          AppSnackBar.show(
            message: result.message,
            isSuccess: result.success,
            isError: !result.success,
          );

          context.pop();
        }
      } else {
        AppSnackBar.show(
          message: "Please provide required information",
          isError: true,
        );
      }
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
              Row(
                children: [
                  Expanded(
                    child: DropDownfield<EquipmentSummaryModel>(
                      label: l10n.navEquipment,
                      hint: l10n.selectEquipment,
                      value: offersState.selectedEquipment,
                      items: equipmentOptions.map((e) {
                        return DropdownMenuItem(
                          value: e,
                          child: Text("${e.name}-${e.plateNumber}"),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          offersNotifier.selectEquipment(value);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SectionTitle(title: "Price"),

              const SizedBox(height: 8),

              InputField(
                icon: LucideIcons.coins,
                label: l10n.priceKZT,
                controller: _price,
                hint: "12 000",
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? l10n.required : null,
              ),

              const SizedBox(height: 12),

              SectionTitle(title: "Price Rate"),

              const SizedBox(height: 8),

              PriceRateSelector(
                initialValue: ref.watch(offersProvider).priceRate,
                onChanged: (val) =>
                    ref.read(offersProvider.notifier).setPriceRate(val),
              ),

              const SizedBox(height: 12),

              SectionTitle(
                title: "Select Date",
                trailing: offersState.selectedDate == null
                    ? "* Required"
                    : null,
              ),

              const SizedBox(height: 8),

              DatePickerComponent(
                daysRange: 7, // Pass your dynamic 'x' range here
                isRequired: true, // Shows indicator text
                selectedDate: offersState.selectedDate,
                onDateSelected: (date) {
                  offersNotifier.setDate(date);
                },
              ),

              const SizedBox(height: 12),

              SectionTitle(
                title: "Select Time",
                trailing: offersState.selectedTime == null
                    ? "* Required"
                    : null,
              ),

              const SizedBox(height: 8),

              TimePickerComponent(
                slotLengthMinutes: 30, // 30 minute blocks
                startHour: 9, // Start at 09:00
                endHour: 17, // End at 17:00
                isRequired: true,
                selectedDateTime: offersState.selectedTime,
                onTimeSelected: (updatedDateTime) {
                  offersNotifier.setTime(
                    updatedDateTime,
                  ); // This emits a full DateTime object
                },
              ),

              const SizedBox(height: 12),

              SectionTitle(
                title: "Comments",
                trailing: offersState.selectedTime == null
                    ? "* Required"
                    : null,
              ),

              const SizedBox(height: 8),

              InputField(
                icon: LucideIcons.text,
                label: l10n.comments,
                controller: _comment,
                hint: l10n.equipmentNameHint,
                // validator: (v) => v == null || v.isEmpty ? l10n.required : null,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: l10n.sendOffer,
                      onPressed: onSubmit,
                      isEnabled: canSubmit,
                      isLoading: offersState.isActionActive("offer:create"),
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
