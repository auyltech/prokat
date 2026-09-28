import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/router/post_login_location.dart';
import 'package:prokat/core/widgets/empty_state_tile.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/bookings/booking_create_error_message.dart';
import 'package:prokat/features/bookings/providers/booking_mutation_provider.dart';
import 'package:prokat/features/bookings/widgets/equipment_image_header.dart';
import 'package:prokat/features/bookings/widgets/service_tariff_block.dart';
import 'package:prokat/features/equipment/models/equipment_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/providers/public_equipment_provider.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/features/equipment_share/equipment_share_booking_intent.dart';
import 'package:prokat/features/equipment_share/equipment_share_overlay.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/locations/widgets/address_picker_card.dart';
import 'package:prokat/features/locations/widgets/select_address_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class GuestCreateBookingScreen extends ConsumerStatefulWidget {
  final String equipmentId;

  const GuestCreateBookingScreen({super.key, required this.equipmentId});

  @override
  ConsumerState<GuestCreateBookingScreen> createState() =>
      _GuestCreateBookingScreenState();
}

class _GuestCreateBookingScreenState
    extends ConsumerState<GuestCreateBookingScreen> {
  final _commentController = TextEditingController();

  String? _selectedPriceId;
  int? _restoredSnapshot;
  JobScheduleMode _scheduleMode = JobScheduleMode.none;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  LocationModel? _address;
  bool _submitting = false;
  bool _unavailable = false;
  bool _tariffAnnounced = false;
  bool _locationsRefreshStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreIntent());
      unawaited(_refreshLocationsIfAuthenticated());
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _openCatalog({bool clearIntent = false}) {
    if (clearIntent) {
      unawaited(ref.read(equipmentShareStorageProvider).clearBookingIntent());
    }
    final session = ref.read(authProvider).session;
    context.go(session == null ? AppRoutes.main : AppRoutes.searchList);
  }

  void _handleAppBarBack() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final landing = startupLandingLocation(
      ref.read(appStartupProvider).routeState,
    );
    if (landing != null) context.go(landing);
  }

  void _handlePopInvoked(bool didPop, Object? result) {
    if (didPop) return;
    final landing = startupLandingLocation(
      ref.read(appStartupProvider).routeState,
    );
    if (landing != null) context.go(landing);
  }

  Future<void> _restoreIntent() async {
    final storage = ref.read(equipmentShareStorageProvider);
    final intent = await storage.readBookingIntent();
    if (!mounted) return;

    final decision = decideShareIntent(
      intent: intent,
      equipmentId: widget.equipmentId,
      currentUserId: ref.read(authProvider).session?.user?.id,
    );
    if (decision == ShareIntentDecision.discard) {
      await storage.clearBookingIntent();
      return;
    }
    if (decision != ShareIntentDecision.apply || intent == null) return;

    setState(() {
      _selectedPriceId = intent.priceEntryId;
      _restoredSnapshot = intent.priceSnapshot;
      _commentController.text = intent.comment;
      _scheduleMode = intent.scheduleMode == 'asap'
          ? JobScheduleMode.asap
          : JobScheduleMode.scheduled;
      _selectedDate = DateTime(
        intent.bookedOn.year,
        intent.bookedOn.month,
        intent.bookedOn.day,
      );
      _selectedTime = intent.bookedAt;
      _address = intent.address;
    });

    final equipment = ref
        .read(publicEquipmentProvider(widget.equipmentId))
        .valueOrNull;
    if (equipment != null) _announceTariff(equipment);
  }

  Future<void> _refreshLocationsIfAuthenticated() async {
    if (_locationsRefreshStarted) return;
    if (ref.read(authProvider).session == null) return;
    _locationsRefreshStarted = true;

    final ok = await ref
        .read(locationProvider.notifier)
        .refreshClientLocationsForShare();
    if (!mounted) return;
    if (!ok) {
      AppToast.show(
        message: AppLocalizations.of(context)!.somethingWentWrongTryAgain,
        type: AppToastType.error,
      );
      return;
    }
    await _reconcileAddressWithSaved();
  }

  Future<void> _persistAddress(LocationModel address) async {
    setState(() => _address = address);
    final storage = ref.read(equipmentShareStorageProvider);
    final existing = await storage.readBookingIntent();
    if (existing == null || existing.equipmentId != widget.equipmentId) {
      return;
    }
    await storage.saveBookingIntent(existing.copyWith(address: address));
  }

  Future<void> _reconcileAddressWithSaved() async {
    final pin = _address;
    if (pin == null || (pin.id ?? '').trim().isNotEmpty) return;

    final matched = matchSavedAddress(
      pin,
      ref.read(locationProvider).clientLocations,
    );
    if (matched == null) return;
    await _persistAddress(matched);
  }

  void _announceTariff(Equipment equipment) {
    if (_tariffAnnounced || _selectedPriceId == null) return;
    _tariffAnnounced = true;
    final matches = equipment.prices.where(
      (entry) => entry.id == _selectedPriceId && entry.price > 0,
    );
    final current = matches.isEmpty ? null : matches.first.price;
    final notice = shareTariffNotice(
      tariffExists: matches.isNotEmpty,
      snapshot: _restoredSnapshot,
      currentPrice: current,
    );
    if (!mounted || notice == ShareTariffNotice.none) return;
    final l10n = AppLocalizations.of(context)!;
    if (notice == ShareTariffNotice.missing) {
      setState(() => _selectedPriceId = null);
      AppToast.show(
        message: l10n.shareEquipmentTariffUnavailable,
        type: AppToastType.error,
      );
      return;
    }
    AppToast.show(
      message: l10n.shareEquipmentPriceChanged,
      type: AppToastType.error,
    );
  }

  String? _validationMessage(AppLocalizations l10n) {
    if (_selectedPriceId == null) return l10n.pleaseSelectPrice;
    if (_address == null) return l10n.pleaseSelectLocation;
    if (_scheduleMode == JobScheduleMode.none) return l10n.pleaseSelectDate;
    if (_scheduleMode == JobScheduleMode.scheduled &&
        (_selectedDate == null || _selectedTime == null)) {
      return l10n.pleaseSelectTime;
    }
    if (_scheduleMode == JobScheduleMode.scheduled) {
      final merged = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      if (merged.isBefore(DateTime.now())) return l10n.pleaseSelectTime;
    }
    return null;
  }

  void _applyAsapClock() {
    if (_scheduleMode != JobScheduleMode.asap) return;
    final when = jobScheduleAsapWhen();
    _selectedDate = DateTime(when.year, when.month, when.day);
    _selectedTime = when;
  }

  EquipmentShareBookingIntent _intent(Equipment equipment) {
    return EquipmentShareBookingIntent(
      userId: null,
      equipmentId: widget.equipmentId,
      priceEntryId: _selectedPriceId!,
      priceSnapshot: _selectedPrice(equipment)?.price ?? _restoredSnapshot ?? 0,
      comment: _commentController.text,
      scheduleMode: _scheduleMode == JobScheduleMode.asap
          ? 'asap'
          : 'scheduled',
      bookedOn: _selectedDate!,
      bookedAt: _selectedTime!,
      address: _address!,
    );
  }

  PriceEntry? _selectedPrice(Equipment? equipment) {
    if (equipment == null || _selectedPriceId == null) return null;
    for (final entry in equipment.prices) {
      if (entry.id == _selectedPriceId && entry.price > 0) return entry;
    }
    return null;
  }

  Future<void> _pickAddress() async {
    if (ref.read(authProvider).session != null) {
      final ok = await ref
          .read(locationProvider.notifier)
          .ensureClientLocations(retryOnError: true);
      if (!mounted) return;
      if (!ok) {
        AppToast.show(
          message: AppLocalizations.of(context)!.somethingWentWrongTryAgain,
          type: AppToastType.error,
        );
        return;
      }
      await SelectAddressSheet.show(
        context,
        service: 'address',
        from: 'create_booking',
        equipmentId: widget.equipmentId,
        onChooseOnMap: () => unawaited(_pickShareAddressOnMap()),
      );
      return;
    }

    await _pickShareAddressOnMap();
  }

  Future<void> _pickShareAddressOnMap() async {
    if (!mounted) return;
    final picked = await context.push<LocationModel>(
      AppRoutes.equipmentShareAddressPath(widget.equipmentId),
    );
    if (!mounted || picked == null) return;
    setState(() => _address = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showJobDatePicker(
      context: context,
      current: _selectedDate,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _scheduleMode = JobScheduleMode.scheduled;
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
      if (_selectedTime != null) {
        _selectedTime = jobScheduleResolveTimeOn(
          _selectedDate!,
          _selectedTime!,
        );
      }
    });
  }

  Future<void> _pickTime() async {
    final date = _selectedDate ?? jobScheduleToday();
    final picked = await showJobTimePicker(
      context: context,
      date: date,
      current: _selectedTime,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _scheduleMode = JobScheduleMode.scheduled;
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedTime = picked;
    });
  }

  Future<void> _book(Equipment equipment) async {
    final l10n = AppLocalizations.of(context)!;
    final message = _validationMessage(l10n);
    if (message != null) {
      AppToast.show(message: message, type: AppToastType.error);
      return;
    }

    _applyAsapClock();
    final session = ref.read(authProvider).session;
    if (session == null) {
      final storage = ref.read(equipmentShareStorageProvider);
      await storage.saveBookingIntent(_intent(equipment));
      await storage.saveOverlay(
        EquipmentShareOverlay(
          path: AppRoutes.equipmentSharePath(equipment.id),
          afterAuth: true,
        ),
      );
      if (!mounted) return;
      final from = Uri.encodeComponent(
        AppRoutes.equipmentSharePath(equipment.id),
      );
      context.go('${AppRoutes.login}?from=$from');
      return;
    }

    final ownerId = equipment.owner?.id?.trim();
    final userId = session.user?.id?.trim();
    if (ownerId != null && ownerId.isNotEmpty && ownerId == userId) {
      await AppAlertBottomSheet.show(
        context,
        title: l10n.shareCannotBookOwnEquipment,
        primaryLabel: l10n.ok,
      );
      return;
    }

    if (_submitting) return;
    if (ref.read(bookingMutationProvider).isActionActive('booking:create')) {
      return;
    }
    if (ref.read(locationProvider).isActionActive('location:create')) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await _createOrder(equipment);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createOrder(Equipment equipment) async {
    final l10n = AppLocalizations.of(context)!;
    var address = _address!;

    if ((address.id ?? '').trim().isEmpty) {
      final ok = await ref
          .read(locationProvider.notifier)
          .ensureClientLocations(retryOnError: true);
      if (!mounted) return;
      if (!ok) {
        AppToast.show(
          message: l10n.somethingWentWrongTryAgain,
          type: AppToastType.error,
        );
        return;
      }

      await _reconcileAddressWithSaved();
      if (!mounted) return;
      address = _address!;
    }

    if ((address.id ?? '').trim().isEmpty) {
      final created = await ref
          .read(locationProvider.notifier)
          .createLocation(address, 'guest_share');
      if (!mounted) return;
      if (!created) {
        AppToast.show(
          message: l10n.failedSaveAddress,
          type: AppToastType.error,
        );
        return;
      }
      final saved = ref.read(locationProvider).selectedAddress;
      if ((saved?.id ?? '').trim().isEmpty) {
        AppToast.show(
          message: l10n.failedSaveAddress,
          type: AppToastType.error,
        );
        return;
      }
      address = saved!;
      await _persistAddress(saved);
      if (!mounted) return;
    }

    final entry = _selectedPrice(equipment);
    if (entry == null) {
      setState(() => _selectedPriceId = null);
      AppToast.show(
        message: l10n.shareEquipmentTariffUnavailable,
        type: AppToastType.error,
      );
      return;
    }

    final when = _scheduleMode == JobScheduleMode.asap
        ? jobScheduleAsapWhen()
        : null;
    final date = when == null
        ? DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          )
        : DateTime(when.year, when.month, when.day);
    final time = when ?? _selectedTime!;

    final notifier = ref.read(bookingMutationProvider.notifier);
    notifier.selectEquipment(equipment);
    notifier.selectPriceEntry(entry);
    notifier.selectLocation(address);
    notifier.setDateAndTime(date: date, time: time);
    notifier.setComment(_commentController.text);

    final result = await notifier.createBooking();
    if (!mounted) return;

    if (result.success) {
      await ref.read(equipmentShareStorageProvider).clearBookingIntent();
      if (!mounted) return;
      context.go(AppRoutes.clientOrders);
      return;
    }

    final code = result.errorCode ?? '';
    if (code == 'BOOKING_EQUIPMENT_UNAVAILABLE' ||
        code == 'BOOKING_EQUIPMENT_NOT_FOUND') {
      await ref.read(equipmentShareStorageProvider).clearBookingIntent();
      if (!mounted) return;
      setState(() => _unavailable = true);
      return;
    }
    if (code == 'BOOKING_OWN_EQUIPMENT') {
      await AppAlertBottomSheet.show(
        context,
        title: l10n.shareCannotBookOwnEquipment,
        primaryLabel: l10n.ok,
      );
      return;
    }

    AppToast.show(
      message: bookingCreateErrorMessage(
        l10n: l10n,
        errorCode: code,
        fallback: result.message,
      ),
      type: AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final equipment = ref.watch(publicEquipmentProvider(widget.equipmentId));
    final creating = ref
        .watch(bookingMutationProvider)
        .isActionActive('booking:create');
    final savingAddress = ref
        .watch(locationProvider)
        .isActionActive('location:create');
    final canPop = GoRouter.of(context).canPop();

    ref.listen(authProvider, (previous, next) {
      if (previous?.session == null && next.session != null) {
        unawaited(_refreshLocationsIfAuthenticated());
      }
    });

    ref.listen(publicEquipmentProvider(widget.equipmentId), (previous, next) {
      next.when(
        data: _announceTariff,
        error: (error, _) {
          if (error is PublicEquipmentException && error.statusCode == 404) {
            unawaited(
              ref.read(equipmentShareStorageProvider).clearBookingIntent(),
            );
          }
        },
        loading: () {},
      );
    });

    ref.listen(locationProvider, (previous, next) {
      if (ref.read(authProvider).session == null) return;
      final selected = next.selectedAddress;
      if (selected == null || (selected.id ?? '').trim().isEmpty) return;
      if (selected.id == previous?.selectedAddress?.id &&
          selected.street == previous?.selectedAddress?.street) {
        return;
      }
      setState(() => _address = selected);
    });

    final body = _unavailable
        ? _Unavailable(
            title: l10n.shareEquipmentUnavailable,
            actionLabel: l10n.shareEquipmentOpenCatalog,
            onCatalog: () => _openCatalog(clearIntent: true),
          )
        : equipment.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _Unavailable(
              title:
                  error is PublicEquipmentException && error.statusCode == 404
                  ? l10n.shareEquipmentUnavailable
                  : l10n.somethingWentWrongTryAgain,
              actionLabel: l10n.shareEquipmentOpenCatalog,
              onCatalog: () => _openCatalog(
                clearIntent:
                    error is PublicEquipmentException &&
                    error.statusCode == 404,
              ),
            ),
            data: (item) => _Card(
              equipment: item,
              selectedPriceId: _selectedPriceId,
              address: _address,
              scheduleMode: _scheduleMode,
              selectedDate: _selectedDate,
              selectedTime: _selectedTime,
              commentController: _commentController,
              locale: l10n.localeName,
              submitting: _submitting || creating || savingAddress,
              onSelectPrice: (id) => setState(() => _selectedPriceId = id),
              onAddress: () => unawaited(_pickAddress()),
              onScheduled: () =>
                  setState(() => _scheduleMode = JobScheduleMode.scheduled),
              onAsap: () {
                final when = jobScheduleAsapWhen();
                setState(() {
                  _scheduleMode = JobScheduleMode.asap;
                  _selectedDate = DateTime(when.year, when.month, when.day);
                  _selectedTime = when;
                });
              },
              onPickDate: () => unawaited(_pickDate()),
              onPickTime: () => unawaited(_pickTime()),
              onBook: () => unawaited(_book(item)),
            ),
          );

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: _handlePopInvoked,
      child: Scaffold(
        appBar: ProkatAppBar(
          title: Text(l10n.createBooking),
          onBack: _handleAppBarBack,
        ),
        body: body,
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onCatalog;

  const _Unavailable({
    required this.title,
    required this.actionLabel,
    required this.onCatalog,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EmptyStateTile(
          imageName: 'empty_equipment.png',
          title: title,
          actionButton: AppElevatedButton(title: actionLabel, onTap: onCatalog),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Equipment equipment;
  final String? selectedPriceId;
  final LocationModel? address;
  final JobScheduleMode scheduleMode;
  final DateTime? selectedDate;
  final DateTime? selectedTime;
  final TextEditingController commentController;
  final String locale;
  final bool submitting;
  final ValueChanged<String> onSelectPrice;
  final VoidCallback onAddress;
  final VoidCallback onScheduled;
  final VoidCallback onAsap;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onBook;

  const _Card({
    required this.equipment,
    required this.selectedPriceId,
    required this.address,
    required this.scheduleMode,
    required this.selectedDate,
    required this.selectedTime,
    required this.commentController,
    required this.locale,
    required this.submitting,
    required this.onSelectPrice,
    required this.onAddress,
    required this.onScheduled,
    required this.onAsap,
    required this.onPickDate,
    required this.onPickTime,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final description = shortDescriptionOf(equipment);
    final prices = equipment.prices.where((entry) => entry.price > 0).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        EquipmentImageHeader(imageUrls: equipment.displayImageUrls),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                equipment.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
              if (prices.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...prices.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ServiceTariffBlock(
                      entry: entry,
                      selected: selectedPriceId == entry.id,
                      onTap: () => onSelectPrice(entry.id),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              AddressPickerCard(
                selectedAddress: address,
                isRequired: address == null,
                requiredHintText: l10n.requestRequiredHint,
                onTap: onAddress,
              ),
              const SizedBox(height: 12),
              JobScheduleSection(
                mode: scheduleMode,
                requiredHint: l10n.requestRequiredHint,
                selectedDate: selectedDate,
                selectedTime: selectedTime,
                locale: locale,
                onScheduled: onScheduled,
                onAsap: onAsap,
                onPickDate: onPickDate,
                onPickTime: onPickTime,
              ),
              const SizedBox(height: 20),
              AppTextArea(
                title: l10n.comments,
                hint: l10n.requestCommentHint,
                controller: commentController,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              AppElevatedButton(
                title: l10n.reserveNow,
                onTap: submitting ? null : onBook,
                isLoading: submitting,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
