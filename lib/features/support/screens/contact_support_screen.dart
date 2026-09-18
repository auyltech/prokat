import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
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
  final _topicController = TextEditingController();

  ContactInquiryTopic? _selectedTopic;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  bool _isLoading = false;
  bool _topicPickerOpen = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _messageController.clear();
    _topicController.clear();
    _selectedTopic = null;
    _autovalidateMode = AutovalidateMode.disabled;
    _formKey = GlobalKey<FormState>();
  }

  bool get _showErrors => _autovalidateMode != AutovalidateMode.disabled;

  Future<void> _pickTopic() async {
    if (_topicPickerOpen) return;
    FocusScope.of(context).unfocus();
    setState(() => _topicPickerOpen = true);
    final selected = await InquiryTopicSheet.show(
      context,
      selectedTopic: _selectedTopic,
    );
    if (!mounted) return;
    setState(() {
      _topicPickerOpen = false;
      if (selected != null) {
        _selectedTopic = selected;
        _topicController.text = selected.localizedLabel(
          AppLocalizations.of(context)!,
        );
      }
    });
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    final curr = _formKey.currentState;
    final hasFieldErrors =
        (_nameController.text.trim().length < 2) ||
        _emailError(l10n) != null ||
        _phoneController.text.trim().isEmpty ||
        _selectedTopic == null ||
        (_messageController.text.trim().length < 10);

    if (curr == null || !curr.validate() || hasFieldErrors) {
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

      AppToast.show(
        message: result.success ? l10n.supportTicketSubmitted : result.message,
        type: result.success ? AppToastType.success : AppToastType.error,
      );

      if (result.success) {
        setState(_resetForm);
      }
    } catch (error) {
      AppToast.show(
        message: l10n.failedToSubmitTicket,
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _emailError(AppLocalizations l10n) {
    final email = _emailController.text.trim();
    if (email.isEmpty) return l10n.pleaseEnterEmail;
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return l10n.invalidEmail;
    return null;
  }

  void _onFieldChanged() {
    if (_showErrors) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSubmitting = ref.watch(supportProvider).isSubmitting;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.s12$md,
                  vertical: AppDimens.s12$md,
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
                      const SizedBox(height: AppDimens.s24$xl),

                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.r16$xl),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.s20$lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppDimens.s08$sm),
                                  Text(
                                    l10n.contactInformation,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.8),

                              AppTextField(
                                controller: _nameController,
                                title: l10n.fullNameRequiredLabel,
                                hint: l10n.fullNameRequiredLabel,
                                isRequired: true,
                                prefix: const Icon(
                                  Icons.account_circle_outlined,
                                ),
                                showError: _showErrors,
                                errorText:
                                    _nameController.text.trim().length < 2
                                    ? l10n.fullNameValidation
                                    : null,
                                onChanged: (_) => _onFieldChanged(),
                                validator: (value) =>
                                    (value == null || value.trim().length < 2)
                                    ? l10n.fullNameValidation
                                    : null,
                              ),
                              const SizedBox(height: AppDimens.s16$base),

                              AppTextField(
                                controller: _emailController,
                                title: l10n.emailAddressRequiredLabel,
                                hint: l10n.emailAddressRequiredLabel,
                                isRequired: true,
                                keyboardType: TextInputType.emailAddress,
                                prefix: const Icon(Icons.email_outlined),
                                showError: _showErrors,
                                errorText: _emailError(l10n),
                                onChanged: (_) => _onFieldChanged(),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return l10n.pleaseEnterEmail;
                                  }
                                  final emailRegex = RegExp(
                                    r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  );
                                  if (!emailRegex.hasMatch(email)) {
                                    return l10n.invalidEmail;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppDimens.s16$base),

                              AppTextField(
                                controller: _phoneController,
                                title: l10n.phoneNumberRequiredLabel,
                                hint: l10n.phoneNumberRequiredLabel,
                                isRequired: true,
                                keyboardType: TextInputType.phone,
                                prefix: const Icon(Icons.phone_outlined),
                                showError: _showErrors,
                                errorText: _phoneController.text.trim().isEmpty
                                    ? l10n.phoneNumberRequired
                                    : null,
                                onChanged: (_) => _onFieldChanged(),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? l10n.phoneNumberRequired
                                    : null,
                              ),

                              const SizedBox(height: AppDimens.s32$xxl),

                              Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppDimens.s08$sm),
                                  Text(
                                    l10n.inquiryDetails,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.8),

                              AppTextField(
                                controller: _topicController,
                                title: l10n.inquiryTopicRequiredLabel,
                                hint: l10n.inquiryTopicRequiredLabel,
                                isRequired: true,
                                selectOnly: true,
                                forceFocused: _topicPickerOpen,
                                onTap: _pickTopic,
                                prefix: const Icon(Icons.unfold_more_rounded),
                                suffix: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: context.colors.text.secondary,
                                ),
                                showError: _showErrors,
                                errorText: _selectedTopic == null
                                    ? l10n.inquiryTopicValidation
                                    : null,
                              ),
                              const SizedBox(height: AppDimens.s16$base),

                              AppTextArea(
                                controller: _messageController,
                                title: l10n.yourMessageRequiredLabel,
                                hint: l10n.yourMessageRequiredLabel,
                                isRequired: true,
                                minLines: 5,
                                maxLines: 5,
                                prefix: const Icon(Icons.edit_note_rounded),
                                showError: _showErrors,
                                errorText:
                                    _messageController.text.trim().length < 10
                                    ? l10n.messageValidation
                                    : null,
                                onChanged: (_) => _onFieldChanged(),
                                validator: (value) =>
                                    (value == null || value.trim().length < 10)
                                    ? l10n.messageValidation
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.s24$xl),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.s04$xs,
                        ),
                        child: AppElevatedButton(
                          title: l10n.submitInquiry,
                          onTap: isSubmitting ? null : _submitForm,
                          isLoading: isSubmitting,
                          isExpanded: false,
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
