import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/owner/models/owner_profile_edit.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/owner/widgets/admin_comment_block.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerProfileForm extends ConsumerStatefulWidget {
  final OwnerProfileModel initialProfile;

  const OwnerProfileForm({super.key, required this.initialProfile});

  @override
  ConsumerState<OwnerProfileForm> createState() => _OwnerProfileFormState();
}

class _OwnerProfileFormState extends ConsumerState<OwnerProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyNameController;
  late final TextEditingController _legalNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cityController;

  OwnerType? _selectedOwnerType;
  String? _selectedCity;
  bool _lastHasChanges = false;
  bool _isEditing = false;
  bool _showFieldErrors = false;
  bool _cityPickerOpen = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;

    _companyNameController = TextEditingController(text: profile.companyName);
    _legalNameController = TextEditingController(text: profile.legalName);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _phoneController = TextEditingController.fromValue(
      kzPhoneEditingValue(profile.phoneNumber),
    );
    _descriptionController = TextEditingController(
      text: profile.serviceDescription,
    );
    _cityController = TextEditingController();

    _selectedOwnerType = profile.ownerType ?? OwnerType.individual;
    _selectedCity =
        canonicalCity(
          profile.city,
          catalogCityKeys(ref.read(catalogProvider).valueOrNull),
        ) ??
        ((profile.city ?? '').trim().isEmpty ? null : profile.city!.trim());

    _firstNameController.addListener(_onFieldsChanged);
    _lastNameController.addListener(_onFieldsChanged);
    _phoneController.addListener(_onFieldsChanged);
    _descriptionController.addListener(_onFieldsChanged);
  }

  String _profileIdentity(OwnerProfileModel profile) {
    return [
      profile.status?.name,
      profile.adminComment,
      profile.firstName,
      profile.lastName,
      profile.phoneNumber,
      profile.city,
      profile.serviceDescription,
    ].join('|');
  }

  void _hydrateFrom(OwnerProfileModel profile) {
    _companyNameController.text = profile.companyName ?? '';
    _legalNameController.text = profile.legalName ?? '';
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _phoneController.value = kzPhoneEditingValue(profile.phoneNumber);
    _descriptionController.text = profile.serviceDescription ?? '';
    _selectedOwnerType = profile.ownerType ?? OwnerType.individual;
    _selectedCity =
        canonicalCity(
          profile.city,
          catalogCityKeys(ref.read(catalogProvider).valueOrNull),
        ) ??
        ((profile.city ?? '').trim().isEmpty ? null : profile.city!.trim());
    _lastHasChanges = false;
    _showFieldErrors = false;
  }

  @override
  void didUpdateWidget(covariant OwnerProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_profileIdentity(oldWidget.initialProfile) ==
        _profileIdentity(widget.initialProfile)) {
      return;
    }
    _hydrateFrom(widget.initialProfile);
    if (_isLocked) _isEditing = false;
  }

  void _startEditing() {
    if (_isLocked) return;
    _hydrateFrom(widget.initialProfile);
    setState(() => _isEditing = true);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_onFieldsChanged);
    _lastNameController.removeListener(_onFieldsChanged);
    _phoneController.removeListener(_onFieldsChanged);
    _descriptionController.removeListener(_onFieldsChanged);
    _companyNameController.dispose();
    _legalNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    final next = _hasChanges;
    if (next == _lastHasChanges) return;
    _lastHasChanges = next;
    if (mounted) setState(() {});
  }

  bool get _isLocked =>
      isOwnerBusinessProfileLocked(widget.initialProfile.status);

  bool get _hasChanges => ownerBusinessProfileHasChanges(
    current: widget.initialProfile,
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    phoneNumber: _phoneController.text,
    city: _selectedCity,
    serviceDescription: _descriptionController.text,
  );

  bool get _hasMissingRequired =>
      _firstNameController.text.trim().isEmpty ||
      _lastNameController.text.trim().isEmpty ||
      normalizeKzPhone(_phoneController.text) == null ||
      (_selectedCity ?? '').trim().isEmpty ||
      _descriptionController.text.trim().isEmpty;

  Future<void> _pickCity() async {
    if (_cityPickerOpen) return;
    setState(() => _cityPickerOpen = true);
    final selected = await CityPickerSheet.show(
      context: context,
      service: CitySelectorService.ownerprofile,
      highlightedCity: _selectedCity,
    );
    if (!mounted) return;
    setState(() => _cityPickerOpen = false);
    if (selected == null || selected.isEmpty) return;

    final next =
        canonicalCity(
          selected,
          catalogCityKeys(ref.read(catalogProvider).valueOrNull),
        ) ??
        selected;
    setState(() {
      _selectedCity = next;
      _lastHasChanges = _hasChanges;
    });
  }

  Future<void> _submitForm() async {
    if (_isLocked) return;
    if (_hasMissingRequired) {
      setState(() => _showFieldErrors = true);
      return;
    }
    if (!_hasChanges) return;

    final isOrganization = _selectedOwnerType == OwnerType.organization;
    final companyName = isOrganization
        ? _companyNameController.text.trim()
        : '';
    final legalName = isOrganization ? _legalNameController.text.trim() : '';
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phoneNumber = normalizeKzPhone(_phoneController.text);
    final serviceDescription = _descriptionController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await AppAlertBottomSheet.show(
      context,
      title: l10n.profileUpdateNeedsModeration,
      primaryLabel: l10n.yes,
      secondaryLabel: l10n.no,
    );
    if (!mounted || confirmed != true) return;

    final updatedProfile = widget.initialProfile.copyWith(
      ownerType: _selectedOwnerType,
      companyName: companyName,
      legalName: legalName,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber ?? '',
      serviceDescription: serviceDescription,
      city: _selectedCity,
    );

    final success = await ref
        .read(ownerRegistrationMutationProvider.notifier)
        .updateOwnerProfile(updatedProfile, submitForReview: true);

    if (!mounted) return;

    if (success && !isOrganization) {
      _companyNameController.clear();
      _legalNameController.clear();
    }

    if (success) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _isEditing = false);
    }

    AppToast.show(
      message: success
          ? l10n.profileSentForModeration
          : ref.read(ownerRegistrationMutationProvider).error ??
                l10n.failedToUpdateProfile,
      type: success ? AppToastType.success : AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providerState = ref.watch(ownerRegistrationMutationProvider);
    final isLoading = providerState.isLoading;
    final isLocked = _isLocked;
    final isEditing = !isLocked && _isEditing;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;

    final hasCity = (_selectedCity ?? '').trim().isNotEmpty;
    final cityLabel = hasCity
        ? catalogCityLabel(
            city: _selectedCity!,
            languageCode: locale,
            catalog: catalog,
            fallback: (city) => localizedCityName(city, l10n),
          )
        : '';
    if (_cityController.text != cityLabel) {
      _cityController.text = cityLabel;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isEditing) ...[
            _ProfileReadOnlyRow(
              label: l10n.firstName,
              value: widget.initialProfile.firstName,
            ),
            const SizedBox(height: AppDimens.s12$md),
            _ProfileReadOnlyRow(
              label: l10n.lastName,
              value: widget.initialProfile.lastName,
            ),
            const SizedBox(height: AppDimens.s12$md),
            _ProfileReadOnlyRow(
              label: l10n.phoneNumber,
              value: maskedKzPhone(widget.initialProfile.phoneNumber),
              helperText: l10n.ownerContactPhoneHint,
            ),
            const SizedBox(height: AppDimens.s12$md),
            _ProfileReadOnlyRow(
              label: l10n.city,
              value: catalogCityLabelOf(
                ref,
                context,
                widget.initialProfile.city,
              ),
            ),
            const SizedBox(height: AppDimens.s12$md),
            _ProfileReadOnlyRow(
              label: l10n.serviceDetails,
              value: widget.initialProfile.serviceDescription,
            ),
            _OwnerProfileStatusBlock(profile: widget.initialProfile),
            if (!isLocked) ...[
              const SizedBox(height: AppDimens.s32$xxl),
              AppElevatedButton(
                title: l10n.editProfileData,
                onTap: _startEditing,
              ),
            ],
          ] else ...[
            AppTextField(
              title: l10n.firstName,
              hint: l10n.enterFirstName,
              controller: _firstNameController,
              isRequired: true,
              showError: _showFieldErrors,
              errorText: _firstNameController.text.trim().isEmpty
                  ? l10n.cannotBeEmpty
                  : null,
              onChanged: (_) {
                if (_showFieldErrors) setState(() {});
              },
            ),
            const SizedBox(height: AppDimens.s16$base),
            AppTextField(
              title: l10n.lastName,
              hint: l10n.enterLastName,
              controller: _lastNameController,
              isRequired: true,
              showError: _showFieldErrors,
              errorText: _lastNameController.text.trim().isEmpty
                  ? l10n.cannotBeEmpty
                  : null,
              onChanged: (_) {
                if (_showFieldErrors) setState(() {});
              },
            ),
            const SizedBox(height: AppDimens.s16$base),
            AppKzPhoneField(
              controller: _phoneController,
              title: l10n.phoneNumber,
              hint: l10n.phoneHint,
              isRequired: true,
              showError: _showFieldErrors,
              errorText: normalizeKzPhone(_phoneController.text) == null
                  ? l10n.enterValidPhoneNumber
                  : null,
              onChanged: (_) {
                if (_showFieldErrors) setState(() {});
              },
            ),
            const SizedBox(height: AppDimens.inputHelperGap),
            Text(
              l10n.ownerContactPhoneHint,
              style: AppFonts.caption(context)
                  .copyWith(color: context.colors.text.tertiary),
            ),
            const SizedBox(height: AppDimens.s16$base),
            AppTextField(
              controller: _cityController,
              title: l10n.city,
              hint: l10n.selectCity,
              isRequired: true,
              selectOnly: true,
              forceFocused: _cityPickerOpen,
              onTap: _pickCity,
              showError: _showFieldErrors,
              errorText: hasCity ? null : l10n.cannotBeEmpty,
              prefix: Icon(
                hasCity ? Icons.location_on : Icons.location_on_outlined,
              ),
              suffix: Icon(
                Icons.expand_more_rounded,
                size: AppDimens.s24$xl,
                color: context.colors.text.secondary,
              ),
            ),
            const SizedBox(height: AppDimens.s16$base),
            AppTextArea(
              title: l10n.serviceDetails,
              hint: l10n.serviceDetailsHint,
              controller: _descriptionController,
              isRequired: true,
              minLines: 3,
              maxLines: 4,
              maxLength: 100,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              showError: _showFieldErrors,
              errorText: _descriptionController.text.trim().isEmpty
                  ? l10n.cannotBeEmpty
                  : null,
              onChanged: (_) {
                if (_showFieldErrors) setState(() {});
              },
            ),
            const SizedBox(height: 28),
            AppElevatedButton(
              title: l10n.submitChangesForReview,
              isLoading: isLoading,
              onTap: (isLoading || !_hasChanges)
                  ? null
                  : () => unawaited(_submitForm()),
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerProfileStatusBlock extends StatelessWidget {
  final OwnerProfileModel profile;

  const _OwnerProfileStatusBlock({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = profile.status;
    if (!shouldShowOwnerProfileStatusBanner(status)) {
      return const SizedBox.shrink();
    }

    final (title, subtitle, color, icon) = switch (status) {
      OwnerRegistrationStatus.pending => (
        l10n.ownerProfilePendingReview,
        l10n.ownerProfilePendingReviewHint,
        Colors.blue,
        Icons.hourglass_top,
      ),
      OwnerRegistrationStatus.rejected => (
        l10n.verificationFailed,
        l10n.statusRejectedSubtitle,
        Colors.red,
        Icons.error_outline,
      ),
      OwnerRegistrationStatus.suspended => (
        l10n.ownerProfileSuspended,
        l10n.ownerProfileSuspendedHint,
        Colors.red,
        Icons.block,
      ),
      OwnerRegistrationStatus.incomplete ||
      OwnerRegistrationStatus.approved ||
      null => ('', '', Colors.transparent, Icons.info_outline),
    };

    if (title.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimens.s24$xl),
        Card(
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(title),
            subtitle: Text(subtitle),
          ),
        ),
        if (status == OwnerRegistrationStatus.rejected) ...[
          const SizedBox(height: AppDimens.s16$base),
          AdminCommentBlock(comment: profile.adminComment),
        ],
      ],
    );
  }
}

class _ProfileReadOnlyRow extends StatelessWidget {
  final String label;
  final String? value;
  final String? helperText;

  const _ProfileReadOnlyRow({
    required this.label,
    required this.value,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = (value ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimens.s04$xs),
        Text(
          display.isEmpty ? '—' : display,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: display.isEmpty
                ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                : null,
          ),
        ),
        if (helperText != null && helperText!.trim().isNotEmpty) ...[
          const SizedBox(height: AppDimens.s04$xs),
          Text(
            helperText!,
            style: AppFonts.caption(context)
                .copyWith(color: context.colors.text.tertiary),
          ),
        ],
      ],
    );
  }
}
