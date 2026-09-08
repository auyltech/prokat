import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/action_button.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/features/support/models/contact_inquiry_topic.dart';
import 'package:prokat/features/support/state/support_provider.dart';
import 'package:prokat/features/support/widgets/inquiry_topic_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  ContactInquiryTopic? _selectedTopic;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _messageController.clear();
    _selectedTopic = null;
    _autovalidateMode = AutovalidateMode.disabled;
    _formKey = GlobalKey<FormState>();
  }

  Future<void> _pickTopic(FormFieldState<ContactInquiryTopic> field) async {
    FocusScope.of(context).unfocus();
    final selected = await InquiryTopicSheet.show(
      context,
      selectedTopic: field.value ?? _selectedTopic,
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedTopic = selected);
    field.didChange(selected);
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    final curr = _formKey.currentState;
    if (curr == null || !curr.validate() || _selectedTopic == null) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref
          .read(supportProvider.notifier)
          .submitInquiry(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            topic: _selectedTopic!.apiValue,
            message: _messageController.text.trim(),
          );

      if (!mounted) return;

      AppSnackBar.show(
        message: result.success ? l10n.supportTicketSubmitted : result.message,
        isSuccess: result.success,
        isError: !result.success,
      );

      if (result.success) {
        setState(_resetForm);
      }
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
                  autovalidateMode: _autovalidateMode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/media/contact_support.png',
                            height: 340,
                            width: 340,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
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
                                    (value == null || value.trim().length < 2)
                                    ? l10n.fullNameValidation
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: buildInputDecoration(
                                  labelText: l10n.emailAddressRequiredLabel,
                                  prefixIcon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return l10n.pleaseEnterEmail;
                                  }
                                  final emailRegex = RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  );
                                  if (!emailRegex.hasMatch(email)) {
                                    return l10n.invalidEmail;
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
                                  labelText: l10n.phoneNumberRequiredLabel,
                                  prefixIcon: Icons.phone_outlined,
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? l10n.phoneNumberRequired
                                    : null,
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

                              FormField<ContactInquiryTopic>(
                                initialValue: _selectedTopic,
                                validator: (value) => value == null
                                    ? l10n.inquiryTopicValidation
                                    : null,
                                builder: (field) {
                                  final selected = field.value;
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _pickTopic(field),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InputDecorator(
                                        isEmpty: selected == null,
                                        decoration:
                                            buildInputDecoration(
                                              labelText: l10n
                                                  .inquiryTopicRequiredLabel,
                                              prefixIcon:
                                                  Icons.unfold_more_rounded,
                                            ).copyWith(
                                              errorText: field.errorText,
                                              suffixIcon: Icon(
                                                Icons.keyboard_arrow_down,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                        child: Text(
                                          selected?.localizedLabel(l10n) ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ),
                                    ),
                                  );
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
                                    (value == null || value.trim().length < 10)
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
