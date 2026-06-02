import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/widgets/date_time_button.dart';
import 'package:prokat/core/widgets/drowp_down_field.dart';
import 'package:prokat/features/equipment/models/equipment_summary_model.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/offers/state/offers_provider.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/utils/date_time.dart';

class CreateOfferScreen extends ConsumerStatefulWidget {
  final RequestModel request;

  const CreateOfferScreen({super.key, required this.request});

  @override
  ConsumerState<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends ConsumerState<CreateOfferScreen> {
  // Declare the form key and controller here
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    // Initialize the controller
    _name = TextEditingController();
  }

  @override
  void dispose() {
    // Safely dispose the controller to prevent memory leaks
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Use ref directly anywhere in the build method since we are inside ConsumerState
    final offersState = ref.watch(offersProvider);
    final offersNotifier = ref.read(offersProvider.notifier);
    final equipmentState = ref.watch(equipmentProvider);

    final equipmentOptions = equipmentState.ownerEquipment
        .map((item) => EquipmentSummaryModel.fromJson(item.toJson()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sendOffer,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey, // Wrapped in a Form to handle the field validation
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
              Text(l10n.navEquipment, style: theme.textTheme.labelMedium),
              const SizedBox(height: 6),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    isExpanded: true,
                    value: offersState.selectedEquipment,
                    hint: Text(l10n.selectEquipment),
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
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: InputField(
                      label: l10n
                          .priceKZT, // Note: updated from startTime to comments
                      controller: _name,
                      hint: "12 000",
                      // keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? l10n.required : null,
                    ),
                    // onChanged: (value) {
                    //   offersNotifier.setPrice(int.tryParse(value) ?? 0);
                    // },
                  ),
                  const SizedBox(width: 12),
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
                              // 1. Safe calculation: use the maximum of the two dates to prevent underflow
                              initialDateTime:
                                  offersState.selectedDate ?? DateTime.now(),
                              minimumDate: DateTime.now(),
                              maximumDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              onDateTimeChanged: (date) {
                                offersNotifier.setDate(date);
                              },
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
                controller: _name,
                hint: l10n.equipmentNameHint,
                validator: (v) => v == null || v.isEmpty ? l10n.required : null,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    // Trigger form validation check
                    if (_formKey.currentState?.validate() ?? false) {
                      // Pass the text controller value into notifier if needed right before sending
                      offersNotifier.setComment(_name.text);

                      final res = await offersNotifier.createOffer();
                      if (res == true && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(
                    l10n.sendOffer,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
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
