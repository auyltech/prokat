import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/parse.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/date_time_button.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';
import 'package:prokat/features/categories/state/category_provider.dart';
import 'package:prokat/features/categories/widgets/user_category_selector.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final capacityController = TextEditingController();
  final rateController = TextEditingController();
  final commentController = TextEditingController();
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  void _openAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SelectAddressSheet(service: "address"),
    );
  }

  // Handle create request
  Future<void> onSubmit() async {
    final selectedCategory = ref.read(categoriesProvider).selectedCategory;

    final requestNotifier = ref.read(requestProvider.notifier);

    if (selectedCategory == null) {
      AppSnackBar.show(context, message: "Please select category", isError: true);
      return;
    }

    final res = await requestNotifier.createRequest(
      categoryId: selectedCategory.id,
      capacity: capacityController.text.trim(),
      offeredRate: parseNullableInt(rateController.text.trim()) ?? 0,
      comment: commentController.text.trim(),
    );

    if (mounted && res == true) {
      AppSnackBar.show(context, message: _l10n.requestCreated, isSuccess: true);
      context.pop();
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final clientRequests = ref.read(requestProvider);
      final active = clientRequests.requests
          .where((r) => ["CREATED", "VIEWED"].contains(r.status))
          .toList();

      if (active.isNotEmpty && context.mounted) {
        context.push(AppRoutes.clientRequests);
      } else {
        ref.read(locationProvider.notifier).getRenterLocations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final locationState = ref.watch(locationProvider);
    final requestState = ref.watch(requestProvider);
    final requestNotifier = ref.read(requestProvider.notifier);
    final categoriesProv = ref.watch(categoriesProvider);

    ref.listen(locationProvider, (previous, next) {
      final address = next.selectedAddress;

      if (address != null && address.id != null) {
        ref.read(requestProvider.notifier).selectLocation(address);
      }
    });

    ref.listen(userProfileProvider, (previous, next) {
      final profileCategoryId = next.userProfile?.selectedCategoryId;

      final foundCategory = categoriesProv.categories
          .where((item) => item.id == profileCategoryId)
          .firstOrNull;

      if (profileCategoryId != null && foundCategory != null) {
        ref.read(requestProvider.notifier).selectCategory(foundCategory);
      }
    });

    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const UserCategorySelector(mode: "create_request"),

                const SizedBox(height: 24),

                SectionTitle(title: l10n.deliveryLocation),

                const SizedBox(height: 6),

                AddressPickerCard(
                  selectedAddress: locationState.selectedAddress,
                  onTap: () => _openAddressSheet(context),
                ),

                const SizedBox(height: 24),

                SectionTitle(title: l10n.equipmentSpecs),

                const SizedBox(height: 6),

                InputField(
                  label: l10n.requiredCapacity,
                  controller: capacityController,
                  hint: l10n.capacityHint,
                  icon: Icons.high_quality_rounded,
                ),
                const SizedBox(height: 12),
                InputField(
                  label: l10n.offeredRate,
                  controller: rateController,
                  hint: l10n.offeredRateHint,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 12),
                InputField(
                  label: l10n.comments,
                  controller: commentController,
                  hint: l10n.additionalDetails,
                  icon: Icons.chat_bubble_outline_rounded,
                ),

                const SizedBox(height: 24),

                SectionTitle(title: l10n.dateAndTime),

                const SizedBox(height: 6),

                Row(
                  children: [
                    Expanded(
                      child: DateTimeButton(
                        icon: Icons.calendar_today_rounded,
                        label: requestState.selectedDate == null
                            ? l10n.selectDate
                            : DateFormat(
                                'MMM dd, yyyy',
                              ).format(requestState.selectedDate!),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) requestNotifier.setDate(date);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DateTimeButton(
                        icon: Icons.access_time_rounded,
                        label: requestState.selectedTime == null
                            ? l10n.selectTime
                            : TimeOfDay.fromDateTime(
                                requestState.selectedTime!,
                              ).format(context),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final now = DateTime.now();
                            requestNotifier.setTime(
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
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                PrimaryButton(
                  label: l10n.create,
                  onPressed: onSubmit,
                  isLoading: requestState.isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
