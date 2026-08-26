import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
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

  // Static list example of label/value city configurations
  final List<Map<String, String>> _citiesList = [
    {'label': 'Atyrau', 'value': 'atyrau'},
    {'label': 'Almaty', 'value': 'almaty'},
    {'label': 'Astana', 'value': 'astana'},
    {'label': 'Shymkent', 'value': 'shymkent'},
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;

    _companyNameController = TextEditingController(text: profile.companyName);
    _legalNameController = TextEditingController(text: profile.legalName);
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _descriptionController = TextEditingController(
      text: profile.serviceDescription,
    );

    // Bind state variations directly from the profile instance
    _selectedOwnerType = profile.ownerType ?? OwnerType.individual;
    _selectedCity = profile.city;
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      AppSnackBar.show(
        message: AppLocalizations.of(context)!.pleaseSelectYourCity,
      );
      return;
    }

    final isOrganization = _selectedOwnerType == OwnerType.organization;
    // Controllers keep draft values while toggling type; only persist / clear on save.
    final companyName = isOrganization
        ? _companyNameController.text.trim()
        : '';
    final legalName = isOrganization ? _legalNameController.text.trim() : '';

    final updatedProfile = widget.initialProfile.copyWith(
      ownerType: _selectedOwnerType,
      companyName: companyName,
      legalName: legalName,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      serviceDescription: _descriptionController.text.trim(),
      city: _selectedCity,
    );

    Future.microtask(() async {
      final success = await ref
          .read(ownerRegistrationMutationProvider.notifier)
          .updateOwnerProfile(updatedProfile);

      if (!mounted) return;

      if (success && !isOrganization) {
        _companyNameController.clear();
        _legalNameController.clear();
      }

      final l10n = AppLocalizations.of(context)!;
      AppSnackBar.show(
        message: success
            ? l10n.profileUpdatedSuccessfully
            : ref.read(ownerRegistrationMutationProvider).error ??
                  l10n.failedToUpdateProfile,
        isSuccess: success,
        isError: !success,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final providerState = ref.watch(ownerRegistrationMutationProvider);
    final isLoading = providerState.isLoading;

    final isOrganization = _selectedOwnerType == OwnerType.organization;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          // Owner Type Selector
          Text(
            l10n.ownerType,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildTypeButton(
                l10n.individualOwner,
                OwnerType.individual,
                theme,
              ),
              const SizedBox(width: 12),
              _buildTypeButton(
                l10n.organization,
                OwnerType.organization,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (isOrganization) ...[
            Text(
              l10n.companyInformation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            InputField(
              label: l10n.companyName,
              hint: l10n.enterCompanyName,
              controller: _companyNameController,
              isRequired: true,
            ),

            const SizedBox(height: 12),

            InputField(
              label: l10n.legalEntityName,
              hint: l10n.legalEntityNameHint,
              controller: _legalNameController,
              isRequired: true,
            ),

            const SizedBox(height: 24),
          ],

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

          InputField(
            label: l10n.phoneNumber,
            hint: "+7 (700) 000-00-00",
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            isRequired: true,
            validator: (value) {
              final phone = value?.trim() ?? '';

              if (phone.isNotEmpty && phone.length < 10) {
                return l10n.enterValidPhoneNumber;
              }

              return null;
            },
          ),

          const SizedBox(height: 24),

          // Custom City Selection Field using a Wrap layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.city,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.requiredHint,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Responsive button matrix group using Wrap
          Wrap(
            spacing: 8.0, // Horizontal space between buttons
            runSpacing: 8.0, // Vertical space between wrapped lines
            children: _citiesList.map((city) {
              final cityKey = city['value']!;
              final isSelected = isSameCity(_selectedCity, cityKey);
              final primaryColor = const Color(0xFF0F5A56);

              return ChoiceChip(
                label: Text(localizedCityName(cityKey, l10n)),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedCity = selected ? city['value'] : null;
                  });
                },
                selectedColor: primaryColor.withValues(alpha: 0.1),
                backgroundColor: theme.cardColor,
                labelStyle: TextStyle(
                  color: isSelected ? primaryColor : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? primaryColor
                        : theme.dividerColor.withValues(alpha: 0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                showCheckmark:
                    false, // Hides native check icon for a clean action button style
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
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
            onPressed: isLoading ? null : _submitForm,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, OwnerType value, ThemeData theme) {
    final isSelected = _selectedOwnerType == value;
    final primaryColor = const Color(0xFF0F5A56);
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedOwnerType = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : theme.cardColor,
          side: BorderSide(
            color: isSelected
                ? primaryColor
                : theme.dividerColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
