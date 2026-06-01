import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/equipment/providers/equipment_provider.dart';
import 'package:prokat/features/offers/providers/offers_provider.dart';
import 'package:prokat/features/requests/models/request_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

void openResponseSheet(BuildContext context, RequestModel request) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final theme = Theme.of(context);
          final l10n = AppLocalizations.of(context)!;

          final offersState = ref.watch(offersProvider);
          final offersNotifier = ref.read(offersProvider.notifier);
          final equipmentState = ref.watch(equipmentProvider);

          final equipmentOptions = equipmentState.ownerEquipment
              // .where(
              //   (e) =>
              //       e.category?.id.toString() ==
              //       offersState.selectedRequest?.categoryId,
              // )
              .toList();

          return Container(
            margin: const EdgeInsets.only(top: 60),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 20,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sendOffer,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

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
                        child: _inputBox(
                          theme,
                          label: l10n.priceKZT,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              offersNotifier.setPrice(int.tryParse(value) ?? 0);
                            },
                            decoration: const InputDecoration(
                              hintText: "120 000",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdownBox(
                          theme,
                          label: l10n.priceRateLabel,
                          value: offersState.priceRate,
                          hint: "Per day",
                          items: ["Per hour", "Per day", "Fixed"],
                          onChanged: (value) {
                            offersNotifier.setPriceRate(value ?? "");
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _inputBox(
                          theme,
                          label: l10n.startDate,
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    offersState.selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );

                              if (date != null) {
                                offersNotifier.setDate(date);
                              }
                            },
                            child: Text(
                              offersState.selectedDate != null
                                  ? formatDate(date: offersState.selectedDate!)
                                  : l10n.selectDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _inputBox(
                          theme,
                          label: l10n.startTime,
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (time != null) {
                                final now = DateTime.now();
                                offersNotifier.setTime(
                                  DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    time.hour,
                                    time.minute,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              offersState.selectedTime != null
                                  ? formatTime(
                                      context,
                                      offersState.selectedTime!,
                                    )
                                  : l10n.selectTime,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _inputBox(
                    theme,
                    label: l10n.comments,
                    child: TextField(
                      maxLines: 3,
                      onChanged: (value) {
                        offersNotifier.setComment(value);
                      },
                      decoration: InputDecoration(
                        hintText: l10n.optionalNotesHint,
                        border: InputBorder.none,
                      ),
                    ),
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
                        final res = await offersNotifier.createOffer();
                        if (res == true && context.mounted) {
                          Navigator.pop(context);
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
          );
        },
      );
    },
  );
}

Widget _inputBox(
  ThemeData theme, {
  required String label,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: theme.textTheme.labelMedium),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: child,
      ),
    ],
  );
}

Widget _dropdownBox(
  ThemeData theme, {
  required String label,
  required String? value,
  required String hint,
  required List<String> items,
  required Function(String?) onChanged,
}) {
  return _inputBox(
    theme,
    label: label,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: Text(hint),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
