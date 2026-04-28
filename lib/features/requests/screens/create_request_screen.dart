import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prokat/core/widgets/date_time_button.dart';
import 'package:prokat/core/widgets/industrial_text_field.dart';
import 'package:prokat/features/categories/providers/category_provider.dart';
import 'package:prokat/features/equipment/widgets/owner/category_selector_tile.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/features/requests/state/request_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

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

  void _openAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SelectAddressSheet(),
    );
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(categoriesProvider.notifier).getCategories();
      ref.read(locationProvider.notifier).getRenterLocations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final locationState = ref.watch(locationProvider);
    final requestState = ref.watch(requestProvider);
    final requestNotifier = ref.read(requestProvider.notifier);
    final categoriesProv = ref.watch(categoriesProvider);

    // Auto sync address
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 60, // Adjust height as needed
              floating: true, // AppBar reappears immediately when scrolling up
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                "New Request",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategorySelectorTile(mode: "create_request"),
                    const SizedBox(height: 24),

                    Text(
                      "Delivery Location",
                      style: theme.textTheme.headlineMedium,
                    ),

                    const SizedBox(height: 6),
                    AddressPickerCard(
                      selectedAddress: locationState.selectedAddress,
                      onTap: () => _openAddressSheet(context),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      "Equipment Specs",
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),

                    IndustrialTextField(
                      controller: capacityController,
                      label: "Required Capacity",
                      hint: "e.g. 10 Kub",
                      icon: Icons.high_quality_rounded,
                      onChanged: (value) =>
                          ref.read(requestProvider.notifier).setCapacity(value),
                    ),

                    IndustrialTextField(
                      controller: rateController,
                      label: "Offered Rate",
                      hint: "Price you're willing to pay",
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final rate = int.tryParse(value);
                        if (rate != null) {
                          ref
                              .read(requestProvider.notifier)
                              .setOfferedRate(rate);
                        }
                      },
                    ),
                    IndustrialTextField(
                      controller: commentController,
                      label: "Comments",
                      hint: "Additional details...",
                      icon: Icons.chat_bubble_outline_rounded,
                      maxLines: 3,
                      onChanged: (value) =>
                          ref.read(requestProvider.notifier).setComment(value),
                    ),

                    const SizedBox(height: 24),

                    Text("Date & Time", style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: DateTimeButton(
                            icon: Icons.calendar_today_rounded,
                            label: requestState.selectedDate == null
                                ? "Select Date"
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
                                ? "Select Time"
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

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () async {
                          final res = await requestNotifier.createRequest();
                          if (context.mounted && res == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Request created")),
                            );
                            context.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0, // Flat design looks better in slivers
                        ),
                        child: const Text(
                          "SUBMIT REQUEST",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
