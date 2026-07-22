import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/support/models/contact_enquiry_topic.dart';
import 'package:prokat/features/support/state/support_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

extension ContactInquiryTopicExtension on ContactInquiryTopic {
  String get displayName {
    return name
        .split('_')
        .map((word) {
          return word[0] + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  ContactInquiryTopic _selectedTopic = ContactInquiryTopic.GENERAL;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    final curr = _formKey.currentState;
    if (curr == null || !curr.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref
          .read(supportProvider.notifier)
          .submitInquiry(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            topic: _selectedTopic.name,
            message: _messageController.text.trim(),
          );

      AppSnackBar.show(
        message: result.success
            ? l10n.supportTicketSubmitted
            : result.message,
        isSuccess: result.success,
        isError: !result.success,
      );

      _formKey.currentState?.reset();
      _phoneController.clear();
      _emailController.clear();
    } catch (error) {
      AppSnackBar.show(message: l10n.failedToSubmitTicket, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSubmitting = ref.watch(supportProvider).isSubmitting;

    // Unified input decoration styling builder
    InputDecoration buildInputDecoration({
      required String labelText,
      required IconData prefixIcon,
      String? helperText,
    }) {
      return InputDecoration(
        labelText: labelText,
        helperText: helperText,
        prefixIcon: Icon(
          prefixIcon,
          color: theme.colorScheme.primary.withAlpha(200),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(
          76,
        ), // Subtle surface tint
        alignLabelWithHint: true,
        helperStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
        errorStyle: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(128),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surfaceContainerLow, // Dynamic neutral background
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header introduction section
                      Text(
                        l10n.howCanWeHelp,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.supportFormDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Structured Form Container Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- SECTION 1: Personal Info ---
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.contactInformation,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.8),

                              // Full Name Field
                              TextFormField(
                                controller: _nameController,
                                decoration: buildInputDecoration(
                                  labelText: l10n.fullNameRequiredLabel,
                                  prefixIcon: Icons.account_circle_outlined,
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? l10n.fullNameValidation
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: buildInputDecoration(
                                  labelText: l10n.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  helperText:
                                      l10n.phoneRequiredIfEmailEmpty,
                                ),
                                onChanged: (_) =>
                                    _formKey.currentState?.validate(),
                                validator: (value) {
                                  final phoneEmpty = _phoneController.text
                                      .trim()
                                      .isEmpty;
                                  if (phoneEmpty &&
                                      (value == null || value.trim().isEmpty)) {
                                    return l10n.emailOrPhoneRequired;
                                  }
                                  if (value != null &&
                                      value.trim().isNotEmpty) {
                                    final emailRegex = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    );
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return l10n.invalidEmail;
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone Number Field
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: buildInputDecoration(
                                  labelText: l10n.phoneNumber,
                                  prefixIcon: Icons.phone_outlined,
                                  helperText: l10n.requiredIfEmailEmpty,
                                ),
                                onChanged: (_) =>
                                    _formKey.currentState?.validate(),
                                validator: (value) {
                                  final emailEmpty = _emailController.text
                                      .trim()
                                      .isEmpty;
                                  if (emailEmpty &&
                                      (value == null || value.trim().isEmpty)) {
                                    return l10n.emailOrPhoneRequired;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 32),

                              // --- SECTION 2: Message Details ---
                              Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.inquiryDetails,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.8),

                              // Topic Dropdown
                              DropdownButtonFormField<ContactInquiryTopic>(
                                initialValue: _selectedTopic,
                                decoration: buildInputDecoration(
                                  labelText: l10n.inquiryTopicRequiredLabel,
                                  prefixIcon: Icons.unfold_more_rounded,
                                ),
                                items: ContactInquiryTopic.values.map((topic) {
                                  return DropdownMenuItem(
                                    value: topic,
                                    child: Text(topic.displayName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedTopic = value);
                                  }
                                },
                              ),
                              const SizedBox(height: 16),

                              // Message Field
                              TextFormField(
                                controller: _messageController,
                                maxLines: 5,
                                decoration: buildInputDecoration(
                                  labelText: l10n.yourMessageRequiredLabel,
                                  prefixIcon: Icons.edit_note_rounded,
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? l10n.messageValidation
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Submit Action Layout
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ActionButton(
                          label: l10n.submitInquiry,
                          onPressed: _submitForm,
                          isLoading: isSubmitting,
                          isEnabled: !isSubmitting,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
