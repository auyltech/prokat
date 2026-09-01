import 'dart:async';
import 'package:flutter/material.dart';
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
  String? _initialCity;

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
    _initialCity = _selectedCity;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _legalNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

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
    final needsModeration =
        ownerBusinessProfileHasChanges(
          current: widget.initialProfile,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          city: widget.initialProfile.city,
          serviceDescription: serviceDescription,
        ) ||
        ownerProfileComparableText(_initialCity) !=
            ownerProfileComparableText(_selectedCity);

    if (needsModeration) {
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
    }

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
        .updateOwnerProfile(updatedProfile, submitForReview: needsModeration);

    if (!mounted) return;

    if (success && !isOrganization) {
      _companyNameController.clear();
      _legalNameController.clear();
    }

    AppSnackBar.show(
      message: success
          ? l10n.profileUpdatedSuccessfully
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

    // TODO(Vadim): Временно отключена возможность работать как организация
    // final isOrganization = _selectedOwnerType == OwnerType.organization;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // TODO(Vadim): Временно отключена возможность работать как организация
          // Owner Type Selector
          // Text(
          //   l10n.ownerType,
          //   style: theme.textTheme.labelLarge?.copyWith(
          //     fontWeight: FontWeight.w600,
          //   ),
          // ),
          // const SizedBox(height: 8),
          //
          // Row(
          //   children: [
          //     _buildTypeButton(
          //       l10n.individualOwner,
          //       OwnerType.individual,
          //       theme,
          //     ),
          //     const SizedBox(width: 12),
          //     _buildTypeButton(
          //       l10n.organization,
          //       OwnerType.organization,
          //       theme,
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 16),
          // if (isOrganization) ...[
          //   Text(
          //     l10n.companyInformation,
          //     style: theme.textTheme.titleMedium?.copyWith(
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          //   const SizedBox(height: 12),
          //
          //   InputField(
          //     label: l10n.companyName,
          //     hint: l10n.enterCompanyName,
          //     controller: _companyNameController,
          //     isRequired: true,
          //   ),
          //
          //   const SizedBox(height: 12),
          //
          //   InputField(
          //     label: l10n.legalEntityName,
          //     hint: l10n.legalEntityNameHint,
          //     controller: _legalNameController,
          //     isRequired: true,
          //   ),
          //
          //   const SizedBox(height: 24),
          // ],
          Text(
            l10n.personalContactDetails,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          InputField(
            label: l10n.firstName,
            hint: l10n.enterFirstName,
            controller: _firstNameController,
            isRequired: true,
          ),

          const SizedBox(height: 12),

          InputField(
            label: l10n.lastName,
            hint: l10n.enterLastName,
            controller: _lastNameController,
            isRequired: true,
          ),

          const SizedBox(height: 12),

          KzPhoneInputField(
            controller: _phoneController,
            label: l10n.phoneNumber,
            hint: l10n.phoneHint,
            helperText: l10n.ownerContactPhoneHint,
          ),

          const SizedBox(height: 12),

          CitySelectField(
            city: _selectedCity,
            isRequired: true,
            showIcon: false,
            service: CitySelectorService.ownerprofile,
            onChanged: (city) => setState(() => _selectedCity = city),
          ),

          const SizedBox(height: 12),

          InputField(
            label: l10n.serviceDetails,
            hint: l10n.serviceDetailsHint,
            controller: _descriptionController,
            isLast: true,
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: l10n.updateProfile,
            isLoading: isLoading,
            onPressed: isLoading ? null : () => unawaited(_submitForm()),
          ),
        ],
      ),
    );
  }

  // TODO(Vadim): Временно отключена возможность работать как организация
  // Widget _buildTypeButton(String label, OwnerType value, ThemeData theme) {
  //   final isSelected = _selectedOwnerType == value;
  //   const primaryColor = Color(0xFF0F5A56);
  //   return Expanded(
  //     child: OutlinedButton(
  //       onPressed: () => setState(() => _selectedOwnerType = value),
  //       style: OutlinedButton.styleFrom(
  //         backgroundColor: isSelected
  //             ? primaryColor.withValues(alpha: 0.1)
  //             : theme.cardColor,
  //         side: BorderSide(
  //           color: isSelected
  //               ? primaryColor
  //               : theme.dividerColor.withValues(alpha: 0.5),
  //           width: isSelected ? 2 : 1,
  //         ),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         padding: const EdgeInsets.symmetric(vertical: 14),
  //       ),
  //       child: Text(
  //         label,
  //         style: TextStyle(
  //           color: isSelected ? primaryColor : theme.colorScheme.onSurface,
  //           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
