import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/kz_phone_input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/owner/models/owner_profile_edit.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/models/owner_registration_status.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/features/user/widgets/city_select_field.dart';
import 'package:prokat/l10n/app_localizations.dart';

class OwnerProfileForm extends ConsumerStatefulWidget {
  final OwnerProfileModel initialProfile;

  const OwnerProfileForm({super.key, required this.initialProfile});

  @override
  ConsumerState<OwnerProfileForm> createState() => _OwnerProfileFormState();
}

class _OwnerProfileFormState extends ConsumerState<OwnerProfileForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _companyNameController;
  late final TextEditingController _legalNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;

  // Local state properties for non-text selections
  OwnerType? _selectedOwnerType;
  String? _selectedCity;
  bool _lastHasChanges = false;
  bool _isEditing = false;
  int _shakeTick = 0;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;

    _companyNameController = TextEditingController(text: profile.companyName);
    _legalNameController = TextEditingController(text: profile.legalName);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _phoneController = TextEditingController(
      text: maskedKzPhone(profile.phoneNumber),
    );
    _descriptionController = TextEditingController(
      text: profile.serviceDescription,
    );

    // Bind state variations directly from the profile instance
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
    _phoneController.text = maskedKzPhone(profile.phoneNumber);
    _descriptionController.text = profile.serviceDescription ?? '';
    _selectedOwnerType = profile.ownerType ?? OwnerType.individual;
    _selectedCity =
        canonicalCity(
          profile.city,
          catalogCityKeys(ref.read(catalogProvider).valueOrNull),
        ) ??
        ((profile.city ?? '').trim().isEmpty ? null : profile.city!.trim());
    _lastHasChanges = false;
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

  void _cancelEditing() {
    _hydrateFrom(widget.initialProfile);
    setState(() => _isEditing = false);
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

  Future<void> _submitForm() async {
    if (_isLocked) return;
    if (_hasMissingRequired) {
      setState(() => _shakeTick++);
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l10n.profileUpdateNeedsModeration),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.no),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.yes),
            ),
          ],
        );
      },
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

    AppSnackBar.show(
      message: success
          ? l10n.profileSentForModeration
          : ref.read(ownerRegistrationMutationProvider).error ??
                l10n.failedToUpdateProfile,
      isSuccess: success,
      isError: !success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final providerState = ref.watch(ownerRegistrationMutationProvider);
    final isLoading = providerState.isLoading;
    final isLocked = _isLocked;
    final isEditing = !isLocked && _isEditing;

    // TODO(Vadim): Временно отключена возможность работать как организация
    // final isOrganization = _selectedOwnerType == OwnerType.organization;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.personalContactDetails,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 16),
          if (!isEditing) ...[
            _ProfileReadOnlyRow(
              label: l10n.firstName,
              value: widget.initialProfile.firstName,
            ),
            const SizedBox(height: 12),
            _ProfileReadOnlyRow(
              label: l10n.lastName,
              value: widget.initialProfile.lastName,
            ),
            const SizedBox(height: 12),
            _ProfileReadOnlyRow(
              label: l10n.phoneNumber,
              value: maskedKzPhone(widget.initialProfile.phoneNumber),
              helperText: l10n.ownerContactPhoneHint,
            ),
            const SizedBox(height: 12),
            _ProfileReadOnlyRow(
              label: l10n.city,
              value: catalogCityLabelOf(
                ref,
                context,
                widget.initialProfile.city,
              ),
            ),
            const SizedBox(height: 12),
            _ProfileReadOnlyRow(
              label: l10n.serviceDetails,
              value: widget.initialProfile.serviceDescription,
            ),
            if (!isLocked) ...[
              const SizedBox(height: 32),
              PrimaryButton(
                label: l10n.editProfileData,
                onPressed: _startEditing,
              ),
            ],
          ] else ...[
            InputField(
              label: l10n.firstName,
              hint: l10n.enterFirstName,
              controller: _firstNameController,
              isRequired: true,
              requiredHintText: l10n.requiredInParens,
              requiredHintMuted: true,
              showFieldErrors: false,
              boxed: true,
              shakeTick: _firstNameController.text.trim().isEmpty
                  ? _shakeTick
                  : 0,
            ),
            const SizedBox(height: 16),
            InputField(
              label: l10n.lastName,
              hint: l10n.enterLastName,
              controller: _lastNameController,
              isRequired: true,
              requiredHintText: l10n.requiredInParens,
              requiredHintMuted: true,
              showFieldErrors: false,
              boxed: true,
              shakeTick: _lastNameController.text.trim().isEmpty
                  ? _shakeTick
                  : 0,
            ),
            const SizedBox(height: 16),
            KzPhoneInputField(
              controller: _phoneController,
              label: l10n.phoneNumber,
              hint: l10n.phoneHint,
              helperText: l10n.ownerContactPhoneHint,
              isRequired: true,
              requiredHintText: l10n.requiredInParens,
              requiredHintMuted: true,
              showFieldErrors: false,
              boxed: true,
              shakeTick: normalizeKzPhone(_phoneController.text) == null
                  ? _shakeTick
                  : 0,
            ),
            const SizedBox(height: 16),
            CitySelectField(
              city: _selectedCity,
              isRequired: true,
              showIcon: false,
              enabled: true,
              boxed: true,
              requiredHintText: l10n.requiredInParens,
              requiredHintMuted: true,
              showFieldErrors: false,
              shakeTick: (_selectedCity ?? '').trim().isEmpty ? _shakeTick : 0,
              service: CitySelectorService.ownerprofile,
              onChanged: (city) => setState(() {
                _selectedCity = city;
                _lastHasChanges = _hasChanges;
              }),
            ),
            const SizedBox(height: 16),
            InputField(
              label: l10n.serviceDetails,
              hint: l10n.serviceDetailsHint,
              controller: _descriptionController,
              isRequired: true,
              requiredHintText: l10n.requiredInParens,
              requiredHintMuted: true,
              showFieldErrors: false,
              boxed: true,
              isLast: true,
              minLines: 3,
              maxLines: 4,
              maxLength: 100,
              hintMaxLines: 3,
              keyboardType: TextInputType.multiline,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              shakeTick: _descriptionController.text.trim().isEmpty
                  ? _shakeTick
                  : 0,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: l10n.submitChangesForReview,
              isLoading: isLoading,
              onPressed: isLoading ? null : () => unawaited(_submitForm()),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: isLoading ? null : _cancelEditing,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.7),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
        const SizedBox(height: 4),
        Text(
          display.isEmpty ? '—' : display,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: display.isEmpty
                ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                : null,
          ),
        ),
        if (helperText != null && helperText!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
    );
  }
}
