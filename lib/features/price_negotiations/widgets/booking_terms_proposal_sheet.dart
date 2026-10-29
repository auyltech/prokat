import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/constants/price_rate_options.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/max_int_input_formatter.dart';
import 'package:prokat/core/widgets/job_schedule_section.dart';
import 'package:prokat/core/widgets/ui_kit/flow/prokat_flow_actions.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';
import 'package:prokat/features/bookings/models/booking_model.dart';
import 'package:prokat/features/bookings/models/booking_status.dart';
import 'package:prokat/features/locations/models/location_model.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/price_negotiations/state/price_negotiation_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

Map<String, dynamic> bookingTermsLocationPayload(LocationModel location) => {
  'street': location.street,
  'streetNames': location.streetNames.toJson(),
  'houseNumber': location.houseNumber,
  'city': location.city,
  'cityNames': location.cityNames.toJson(),
  'country': location.country,
  'countryNames': location.countryNames.toJson(),
  'region': location.region,
  'regionNames': location.regionNames.toJson(),
  'comment': location.comment,
  'instructions': location.instructions,
  'latitude': location.latitude,
  'longitude': location.longitude,
};

class BookingTermsProposalSheet extends ConsumerStatefulWidget {
  const BookingTermsProposalSheet({
    super.key,
    required this.booking,
    required this.mode,
    required this.chatId,
  });

  final BookingModel booking;
  final AppMode mode;
  final String chatId;

  static bool canPropose(BookingModel booking) =>
      booking.status == BookingStatus.created &&
      booking.companyId == null &&
      booking.updatedAt != null &&
      booking.bookedOn != null &&
      booking.bookedAt != null &&
      booking.location != null;

  static Future<void> show(
    BuildContext context, {
    required BookingModel booking,
    required AppMode mode,
    required String chatId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (!canPropose(booking)) {
      AppToast.show(
        message: l10n.orderTermsUnavailable,
        type: AppToastType.error,
      );
      return;
    }
    final palette = ProkatFlowPalette.of(context);
    await AppBottomSheet.show<void>(
      context,
      title: l10n.proposeOrderTerms,
      contentBuilder: (_) => ProkatFlowScope(
        palette: palette,
        child: BookingTermsProposalSheet(
          booking: booking,
          mode: mode,
          chatId: chatId,
        ),
      ),
    );
  }

  @override
  ConsumerState<BookingTermsProposalSheet> createState() =>
      _BookingTermsProposalSheetState();
}

class _BookingTermsProposalSheetState
    extends ConsumerState<BookingTermsProposalSheet> {
  late final TextEditingController _priceController;
  final _commentController = TextEditingController();
  late PriceRateOption _rate;
  DateTime? _date;
  DateTime? _time;
  LocationModel? _address;
  JobScheduleMode _mode = JobScheduleMode.scheduled;
  bool _loadingAddresses = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '${widget.booking.price}');
    _rate = widget.booking.priceRate;
    _date = widget.booking.bookedOn?.toLocal();
    _time = widget.booking.bookedAt?.toLocal();
    _address = widget.booking.location;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  bool _sameAddress(LocationModel? a, LocationModel? b) =>
      a == null || b == null
      ? a == b
      : jsonEncode(bookingTermsLocationPayload(a)) ==
            jsonEncode(bookingTermsLocationPayload(b));

  bool _validAddress(LocationModel? address) =>
      address != null &&
      address.street.trim().isNotEmpty &&
      address.city.trim().isNotEmpty &&
      address.country.trim().isNotEmpty &&
      address.latitude.isFinite &&
      address.latitude >= -90 &&
      address.latitude <= 90 &&
      address.longitude.isFinite &&
      address.longitude >= -180 &&
      address.longitude <= 180;

  bool get _scheduleChanged =>
      _mode == JobScheduleMode.asap ||
      _date != widget.booking.bookedOn?.toLocal() ||
      _time != widget.booking.bookedAt?.toLocal();

  bool get _changed =>
      int.tryParse(_priceController.text) != widget.booking.price ||
      _rate.value != widget.booking.priceRate.value ||
      _scheduleChanged ||
      !_sameAddress(_address, widget.booking.location);

  void _scheduled() {
    setState(() {
      _mode = JobScheduleMode.scheduled;
      _date ??= jobScheduleToday();
      _time = jobScheduleResolveTimeOn(
        _date!,
        _time ?? jobScheduleDefaultTimeOn(_date!),
      );
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showJobDatePicker(context: context, current: _date);
    if (!mounted || picked == null) return;
    setState(() {
      _date = picked;
      _time = jobScheduleResolveTimeOn(
        picked,
        _time ?? jobScheduleDefaultTimeOn(picked),
      );
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    final date = _date ?? jobScheduleToday();
    final picked = await showJobTimePicker(
      context: context,
      date: date,
      current: _time,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _date = date;
      _time = jobScheduleResolveTimeOn(date, picked);
      _error = null;
    });
  }

  String _addressLabel(LocationModel address) {
    final language = Localizations.localeOf(context).languageCode;
    return [
      address.streetLine(language),
      address.labelCity(language),
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  Future<LocationModel?> _chooseAddress() async {
    if (_loadingAddresses || _sending) return null;
    setState(() => _loadingAddresses = true);
    final result = await ref.read(locationApiProvider).getClientLocations();
    if (!mounted) return null;
    setState(() => _loadingAddresses = false);
    final l10n = AppLocalizations.of(context)!;
    if (!result.success) {
      setState(() => _error = l10n.somethingWentWrongTryAgain);
      return null;
    }
    final original = widget.booking.location;
    final addresses = <LocationModel>[
      ?original,
      for (final address in result.data ?? <LocationModel>[])
        if (address.service.toUpperCase() == 'ADDRESS' &&
            _validAddress(address) &&
            !_sameAddress(address, original))
          address,
    ];
    return AppBottomSheet.show<LocationModel>(
      context,
      title: l10n.selectAddress,
      contentBuilder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final address in addresses)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.mapPin),
              title: Text(_addressLabel(address)),
              subtitle: identical(address, original)
                  ? Text(l10n.orderTermsCurrentAddress)
                  : null,
              trailing: _sameAddress(address, _address)
                  ? const Icon(LucideIcons.check)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(address),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context)!;
    String? error;
    final price = int.tryParse(_priceController.text);
    if (!BookingTermsProposalSheet.canPropose(widget.booking)) {
      error = l10n.orderTermsUnavailable;
    } else if (price == null || price <= 0 || price > 100000) {
      error = l10n.enterValidPrice;
    } else if (!_changed) {
      error = l10n.orderTermsUnchanged;
    } else if (!_validAddress(_address)) {
      error = l10n.pleaseSelectLocation;
    } else if (_date == null || _time == null) {
      error = l10n.pleaseSelectTime;
    }
    final asap = _mode == JobScheduleMode.asap ? jobScheduleAsapWhen() : null;
    final date = asap == null
        ? _date
        : DateTime(asap.year, asap.month, asap.day);
    final time = asap ?? _time;
    if (error == null && _scheduleChanged && time!.isBefore(DateTime.now())) {
      error = l10n.pleaseSelectTime;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(priceNegotiationMutationProvider.notifier)
          .createCounterOffer(
            price: price!,
            priceRate: _rate.value,
            comment: _commentController.text.trim(),
            type: widget.mode == AppMode.ownerMode
                ? 'OWNER_COUNTER'
                : 'CLIENT_COUNTER',
            bookingId: widget.booking.id,
            chatId: widget.chatId,
            terms: {
              'version': 1,
              'expectedBookingUpdatedAt': widget.booking.updatedAt!
                  .toUtc()
                  .toIso8601String(),
              'bookedOn': date!.toUtc().toIso8601String(),
              'bookedAt': time!.toUtc().toIso8601String(),
              'location': bookingTermsLocationPayload(_address!),
            },
          );
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flow =
        ProkatFlowScope.maybeOf(context) ?? ProkatFlowPalette.of(context);
    final submitting =
        _sending || ref.watch(priceNegotiationMutationProvider).isSubmitting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.orderTermsProposalHint,
          style: AppFonts.body14(context).copyWith(color: flow.secondary),
        ),
        const SizedBox(height: 20),
        AppTextField(
          key: const ValueKey('terms-price'),
          title: l10n.price,
          controller: _priceController,
          enabled: !submitting,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            const MaxIntInputFormatter(100000),
          ],
          prefix: Text(
            '₸',
            style: TextStyle(color: flow.primary, fontWeight: FontWeight.w700),
          ),
          textStyle: AppFonts.headingM(context).copyWith(color: flow.title),
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 16),
        AppDropdownField<PriceRateOption>(
          key: const ValueKey('terms-rate'),
          title: l10n.offerCompareUnit,
          sheetTitle: l10n.offerCompareUnit,
          enabled: !submitting,
          value: _rate,
          selectedLabel: getPriceRate(_rate, l10n: l10n),
          options: [
            for (final rate in priceRateOptions)
              DropdownOption(
                value: rate,
                label: getPriceRate(rate, l10n: l10n),
              ),
          ],
          onChanged: (rate) => setState(() {
            _rate = rate;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        AppDropdownField<LocationModel>(
          key: const ValueKey('terms-address'),
          title: l10n.address,
          hint: l10n.selectAddress,
          sheetTitle: l10n.selectAddress,
          enabled: !submitting && !_loadingAddresses,
          value: _address,
          selectedLabel: _address == null ? null : _addressLabel(_address!),
          prefix: Icon(LucideIcons.mapPin, color: flow.primary),
          openCustomSheet: _chooseAddress,
          onChanged: (address) => setState(() {
            _address = address;
            _error = null;
          }),
        ),
        if (_loadingAddresses) const LinearProgressIndicator(),
        const SizedBox(height: 20),
        IgnorePointer(
          ignoring: submitting,
          child: JobScheduleSection(
            mode: _mode,
            requiredHint: l10n.requestRequiredHint,
            selectedDate: _date,
            selectedTime: _time,
            locale: l10n.localeName,
            onScheduled: _scheduled,
            onAsap: () => setState(() {
              _mode = JobScheduleMode.asap;
              _error = null;
            }),
            onPickDate: _pickDate,
            onPickTime: _pickTime,
          ),
        ),
        const SizedBox(height: 20),
        AppTextArea(
          title: l10n.comments,
          controller: _commentController,
          enabled: !submitting,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 24),
        ProkatFlowPrimaryButton(
          title: l10n.sendOrderTermsProposal,
          loading: submitting,
          onPressed:
              !submitting &&
                  BookingTermsProposalSheet.canPropose(widget.booking) &&
                  _changed
              ? _submit
              : null,
        ),
      ],
    );
  }
}
