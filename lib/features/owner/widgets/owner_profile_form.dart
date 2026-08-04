import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/owner/models/owner_profile_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';

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
      AppSnackBar.show(message: 'Please select your city');
      return;
    }

    final updatedProfile = widget.initialProfile.copyWith(
      ownerType: _selectedOwnerType,
      companyName: _companyNameController.text.trim(),
      legalName: _legalNameController.text.trim(),
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

      AppSnackBar.show(
        message: success
            ? 'Profile updated successfully'
            : ref.read(ownerRegistrationMutationProvider).error ??
                  'Failed to update profile',
        isSuccess: success,
        isError: !success,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
            "Owner Type",
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildTypeButton("Individual", OwnerType.individual, theme),
              const SizedBox(width: 12),
              _buildTypeButton("Organization", OwnerType.organization, theme),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            "Company Information",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          InputField(
            label: "Company Name",
            hint: "Enter company name",
            controller: _companyNameController,
            isRequired: isOrganization,
          ),

          const SizedBox(height: 12),

          InputField(
            label: "Legal entity name",
            hint: "As written in official documents",
            controller: _legalNameController,
            isRequired: isOrganization,
          ),

          const SizedBox(height: 24),

          Text(
            "Personal Contact Details",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          InputField(
            label: "First Name",
            hint: "Enter first name",
            controller: _firstNameController,
            isRequired: true,
          ),

          const SizedBox(height: 12),

          InputField(
            label: "Last Name",
            hint: "Enter last name",
            controller: _lastNameController,
            isRequired: true,
          ),

          const SizedBox(height: 12),

          InputField(
            label: "Phone Number",
            hint: "+7 (700) 000-00-00",
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            isRequired: true,
            validator: (value) {
              final phone = value?.trim() ?? '';

              if (phone.isNotEmpty && phone.length < 10) {
                return 'Enter a valid phone number';
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
                "City",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                "* Required",
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
              final isSelected = _selectedCity == city['value'];
              final primaryColor = const Color(0xFF0F5A56);

              return ChoiceChip(
                label: Text(city['label']!),
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
            label: "Service Details",
            hint: "Describe the goods, rentals or machinery you provide...",
            controller: _descriptionController,
            isLast: true,
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: "Update Profile",
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
