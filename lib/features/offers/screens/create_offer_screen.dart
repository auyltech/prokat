import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/date_time_button.dart';
import 'package:prokat/core/widgets/drowp_down_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/utils/date_time.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  final String requestId;

  const CreateOfferScreen({super.key, required this.requestId});

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
      final request = ref
          .read(requestProvider)
          .ownerRequests
          .where((item) => item.id == widget.requestId)
          .firstOrNull;

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final offersState = ref.watch(offersProvider);
    final offersNotifier = ref.read(offersProvider.notifier);
    final equipmentState = ref.watch(equipmentProvider);

    final equipmentOptions = equipmentState.ownerEquipment
        .map((item) => EquipmentSummaryModel.fromJson(item.toJson()))
        .toList();

    Future<void> onSubmit() async {
      if (_formKey.currentState?.validate() ?? false) {
        offersNotifier.setPrice(parseNullableInt(_price.text) ?? 0);
        offersNotifier.setComment(_comment.text);

        final res = await offersNotifier.createOffer();
        if (res == true && context.mounted) {
          Navigator.pop(context);
        }
      }
    }

    final minDate = DateTime.now();

    final initialDate =
        offersState.selectedDate != null &&
            offersState.selectedDate!.isAfter(minDate)
        ? offersState.selectedDate!
        : minDate;

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

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: InputField(
                      label: l10n.priceKZT,
                      controller: _price,
                      hint: "12 000",
                      // keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.required : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: DateTimeButton(
                      icon: Icons.calendar_today_rounded,
                      label: offersState.selectedDate == null
                          ? l10n.selectDate
                          : formatDate(date: offersState.selectedDate!),
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            height: 300,
                            color: theme.scaffoldBackgroundColor,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: initialDate,
                              minimumDate: minDate,
                              maximumDate: minDate.add(
                                const Duration(days: 365),
                              ),
                              onDateTimeChanged: offersNotifier.setDate,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: DateTimeButton(
                      icon: Icons.access_time_rounded,
                      label: offersState.selectedTime == null
                          ? l10n.selectTime
                          : formatTime(context, offersState.selectedTime!),
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            height: 300,
                            color: theme.scaffoldBackgroundColor,
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.time,
                              use24hFormat: false,
                              initialDateTime:
                                  offersState.selectedTime ??
                                  initialTargetDateTime,
                              onDateTimeChanged: (time) {
                                offersNotifier.setTime(time);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              InputField(
                label: l10n.comments,
                controller: _comment,
                hint: l10n.equipmentNameHint,
                // validator: (v) => v == null || v.isEmpty ? l10n.required : null,
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                label: l10n.sendOffer,
                onPressed: onSubmit,
                isLoading: offersState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
