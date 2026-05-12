import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

class RegisterOwnerPage extends ConsumerStatefulWidget {
  const RegisterOwnerPage({super.key});

  @override
  ConsumerState<RegisterOwnerPage> createState() => _RegisterOwnerPageState();
}

class _RegisterOwnerPageState extends ConsumerState<RegisterOwnerPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _messageController = TextEditingController();

  bool _prefilledFromRequest = false;
  bool _prefilledFromProfile = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ownerRegistrationProvider.notifier).getRegistrationRequest();

      final profileState = ref.read(userProfileProvider);
      if (profileState.userProfile == null && profileState.isLoading != true) {
        ref.read(userProfileProvider.notifier).getUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _prefillFromRequest(RegistrationRequestModel request) {
    _firstNameController.text = request.firstName ?? _firstNameController.text;
    _lastNameController.text = request.lastName ?? _lastNameController.text;
    _phoneController.text = request.phoneNumber ?? _phoneController.text;
    _emailController.text = request.email ?? _emailController.text;
    _cityController.text = request.city ?? _cityController.text;
    _messageController.text = request.message ?? _messageController.text;
  }

  void _prefillFromProfile(UserProfileModel profile) {
    _firstNameController.text = profile.firstName ?? _firstNameController.text;
    _lastNameController.text = profile.lastName ?? _lastNameController.text;
    _phoneController.text = profile.phoneNumber ?? _phoneController.text;
    _cityController.text = profile.city ?? _cityController.text;
  }

  Future<void> _submit() async {
    final state = ref.read(ownerRegistrationProvider);
    final request = state.registrationRequest;

    final status = (request?.status ?? '').toLowerCase();
    if (status == 'accepted') return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final notifier = ref.read(ownerRegistrationProvider.notifier);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final city = _cityController.text.trim();
    final message = _messageController.text.trim();

    final success = request == null
        ? await notifier.createOwnerRegistrationRequest(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            city: city,
            message: message,
          )
        : await notifier.updateOwnerRegistrationRequest(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            city: city,
            message: message,
          );

    if (!mounted) return;

    if (success) {
      AppSnackBar.show(
        context,
        message: request == null ? "Request submitted" : "Request updated",
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final state = ref.watch(ownerRegistrationProvider);
    final request = state.registrationRequest;

    final status = (request?.status ?? '').toLowerCase();
    final isAccepted = status == 'accepted';

    ref.listen(ownerRegistrationProvider, (previous, next) {
      final prevError = previous?.error;
      final nextError = next.error;

      if (nextError != null && nextError.isNotEmpty && nextError != prevError) {
        AppSnackBar.show(context, message: nextError, isError: true);
      }

      final request = next.registrationRequest;
      if (!_prefilledFromRequest && request != null) {
        _prefillFromRequest(request);
        _prefilledFromRequest = true;
      }

      if (request == null && !_prefilledFromProfile) {
        final profile = ref.read(userProfileProvider).userProfile;
        if (profile != null) {
          _prefillFromProfile(profile);
          _prefilledFromProfile = true;
        }
      }
    });

    ref.listen(userProfileProvider, (previous, next) {
      final hasRequest = ref
          .read(ownerRegistrationProvider)
          .registrationRequest;
      if (hasRequest != null) return;

      final profile = next.userProfile;
      if (profile == null) return;

      if (!_prefilledFromProfile) {
        _prefillFromProfile(profile);
        _prefilledFromProfile = true;
      }
    });

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Become a service provider",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        "Join our team and offer your equipment or services to clients.",
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your request will be reviewed by the admin for further processing.",
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      if (request != null) _StatusCard(request: request),
                      if (request != null) const SizedBox(height: 16),

                      _OwnerRegistrationField(
                        controller: _firstNameController,
                        label: "First name",
                        hint: "Enter your first name",
                        icon: Icons.person_outline,
                        enabled: !isAccepted,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return "First name is required";
                          }
                          return null;
                        },
                      ),

                      _OwnerRegistrationField(
                        controller: _lastNameController,
                        label: "Last name",
                        hint: "Enter your last name",
                        icon: Icons.person_outline,
                        enabled: !isAccepted,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return "Last name is required";
                          }
                          return null;
                        },
                      ),
                      _OwnerRegistrationField(
                        controller: _phoneController,
                        label: "Phone number",
                        hint: "Enter your phone number",
                        icon: Icons.phone_outlined,
                        enabled: !isAccepted,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return "Phone number is required";
                          }
                          return null;
                        },
                      ),
                      _OwnerRegistrationField(
                        controller: _emailController,
                        label: "Email",
                        hint: "Enter your email (optional)",
                        icon: Icons.email_outlined,
                        enabled: !isAccepted,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return null;
                          if (!value.contains('@')) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),

                      _OwnerRegistrationField(
                        controller: _cityController,
                        label: "City",
                        hint: "Enter your city",
                        icon: Icons.location_city_outlined,
                        enabled: !isAccepted,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return "City is required";
                          }
                          return null;
                        },
                      ),

                      _OwnerRegistrationField(
                        controller: _messageController,
                        label: "Message",
                        hint:
                            "Briefly describe the service or equipment you can provide.",
                        icon: Icons.message_outlined,
                        enabled: !isAccepted,
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return "Please add a short message";
                          }
                          return null;
                        },
                      ),

                      if (request == null || !isAccepted) ...[
                        const SizedBox(height: 12),
                        Text(
                          "Note: please describe your service/equipment briefly so we can review your request faster.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: _submitLabel(request),
                          isLoading: state.isLoading,
                          icon: Icons.send_rounded,
                          onPressed: state.isLoading ? null : _submit,
                        ),
                      ] else ...[
                        _AcceptedInfo(theme: theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _submitLabel(RegistrationRequestModel? request) {
    if (request == null) return "Submit request";

    final status = (request.status ?? '').toLowerCase();
    if (status == 'rejected') return "Resubmit request";
    if (status == 'created') return "Update request";
    return "Update request";
  }
}

class _StatusCard extends StatelessWidget {
  final RegistrationRequestModel request;

  const _StatusCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final status = (request.status ?? 'created').toLowerCase();
    final adminComment = (request.adminComment ?? '').trim();

    final (title, subtitle, icon, color) = switch (status) {
      'accepted' => (
        "Accepted",
        "You are now approved as a service provider.",
        Icons.verified_rounded,
        Colors.green,
      ),
      'rejected' => (
        "Rejected",
        "Please review the admin comment and update your request.",
        Icons.error_outline_rounded,
        colors.error,
      ),
      _ => (
        "Under review",
        "Your request has been submitted and is being reviewed.",
        Icons.hourglass_top_rounded,
        colors.primary,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.75),
            ),
          ),
          if (adminComment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Admin comment",
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              adminComment,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AcceptedInfo extends StatelessWidget {
  final ThemeData theme;

  const _AcceptedInfo({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your request has been accepted. If you need to change your details, contact support.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerRegistrationField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _OwnerRegistrationField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withValues(alpha: 0.25)),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: colors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
