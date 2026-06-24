import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

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

    if (success && mounted) {
      final l10n = AppLocalizations.of(context)!;

      AppSnackBar.show(
        message: request == null ? l10n.requestSubmitted : l10n.requestUpdated,
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final state = ref.watch(ownerRegistrationProvider);
    final request = state.registrationRequest;

    final status = (request?.status ?? '').toLowerCase();
    final isAccepted = status == 'accepted';

    ref.listen(ownerRegistrationProvider, (previous, next) {
      final prevError = previous?.error;
      final nextError = next.error;

      if (nextError != null && nextError.isNotEmpty && nextError != prevError) {
        AppSnackBar.show(message: nextError, isError: true);
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

    final submitLabel = request == null
        ? l10n.submitRequest
        : (request.status ?? '').toLowerCase() == "rejected"
        ? l10n.resubmitRequest
        : l10n.updateRequest;

    return Scaffold(
      backgroundColor: colors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        l10n.joinTeamHint,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.requestReviewedHint,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      if (request != null) _StatusCard(request: request),
                      if (request != null) const SizedBox(height: 16),

                      InputField(
                        controller: _firstNameController,
                        label: l10n.firstName,
                        hint: l10n.firstNameHint,
                        icon: Icons.person_outline,
                        // enabled: !isAccepted,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return l10n.firstNameRequired;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 8),

                      InputField(
                        controller: _lastNameController,
                        label: l10n.lastName,
                        hint: l10n.lastNameHint,
                        icon: Icons.person_outline,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return l10n.lastNameRequired;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 8),
                      InputField(
                        controller: _phoneController,
                        label: l10n.phoneNumber,
                        hint: l10n.phoneHint,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return l10n.phoneNumberRequired;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 8),
                      InputField(
                        controller: _emailController,
                        label: l10n.email,
                        hint: l10n.emailHint,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return null;
                          if (!value.contains('@')) {
                            return l10n.enterValidEmail;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 8),
                      InputField(
                        controller: _cityController,
                        label: l10n.city,
                        hint: l10n.cityInputHint,
                        icon: Icons.location_city_outlined,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return l10n.cityRequired;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 8),
                      InputField(
                        controller: _messageController,
                        label: l10n.message,
                        hint: l10n.messageHint,
                        icon: Icons.message_outlined,
                        // maxLines: 3,
                        keyboardType: TextInputType.multiline,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return l10n.messageRequired;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 8),

                      if (request == null || !isAccepted) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.noteDescribeHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: submitLabel,
                          isLoading: state.isLoading,
                          icon: Icons.send_rounded,
                          onPressed: state.isLoading ? null : _submit,
                        ),
                      ] else ...[
                        _AcceptedInfo(theme: theme),
                      ],

                      SizedBox(height: 40),
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
}

class _StatusCard extends StatelessWidget {
  final RegistrationRequestModel request;

  const _StatusCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final status = (request.status ?? 'created').toLowerCase();
    final adminComment = (request.adminComment ?? '').trim();

    final (title, subtitle, icon, color) = switch (status) {
      'accepted' => (
        l10n.statusAccepted,
        l10n.statusAcceptedSubtitle,
        Icons.verified_rounded,
        Colors.green,
      ),
      'rejected' => (
        l10n.statusRejected,
        l10n.statusRejectedSubtitle,
        Icons.error_outline_rounded,
        colors.error,
      ),
      _ => (
        l10n.statusUnderReview,
        l10n.statusUnderReviewSubtitle,
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
              l10n.adminComment,
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
    final l10n = AppLocalizations.of(context)!;

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
              l10n.requestAcceptedInfo,
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
