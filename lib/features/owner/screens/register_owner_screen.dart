import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/constants/cities.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/app_snack_bar.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/kz_phone_input_field.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/features/user/widgets/city_select_field.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';

class RegisterOwnerPage extends ConsumerStatefulWidget {
  const RegisterOwnerPage({super.key});

  @override
  ConsumerState<RegisterOwnerPage> createState() => _RegisterOwnerPageState();
}

class _RegisterOwnerPageState extends ConsumerState<RegisterOwnerPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+7');
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedCity;
  bool _prefilledFromRequest = false;

  void _clearFormForAccountChange() {
    _formKey.currentState?.reset();

    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.value = kzPhoneEditingValue(null);
    _emailController.clear();
    _messageController.clear();

    if (!mounted) {
      _selectedCity = null;
      _prefilledFromRequest = false;
      return;
    }

    setState(() {
      _selectedCity = null;
      _prefilledFromRequest = false;
    });
  }

  Future<void> _loadCurrentAccount(String userId) async {
    _tryPrefill();

    await ref.read(clientProfileProvider.notifier).refreshIfStale();

    if (!mounted || ref.read(authProvider).currentUserId != userId) {
      return;
    }

    await ref.read(ownerRegistrationRequestProvider.notifier).refreshIfStale();
    if (mounted) _tryPrefill();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final userId = ref.read(authProvider).currentUserId;

      if (userId != null) {
        _loadCurrentAccount(userId);
      } else {
        _tryPrefill();
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void _setIfEmpty(TextEditingController controller, String? value) {
    if (controller.text.trim().isNotEmpty) return;
    final next = _nonEmpty(value);
    if (next != null) controller.text = next;
  }

  void _applyPhone(String? value) {
    _phoneController.value = kzPhoneEditingValue(value);
  }

  void _setPhoneIfEmpty(String? value) {
    if (nationalKzPhoneDigits(_phoneController.text).isNotEmpty) return;
    if (_nonEmpty(value) == null) return;
    _applyPhone(value);
  }

  String? _canonicalCity(String? city) {
    return canonicalCity(city, cities) ?? _nonEmpty(city);
  }

  void _prefillFromRequest(RegistrationRequestModel request) {
    _firstNameController.text = _nonEmpty(request.firstName) ?? '';
    _lastNameController.text = _nonEmpty(request.lastName) ?? '';
    _applyPhone(request.phoneNumber);
    _emailController.text = _nonEmpty(request.email) ?? '';
    _selectedCity = _canonicalCity(request.city);
    _messageController.text = _nonEmpty(request.message) ?? '';
  }

  void _prefillFromProfile(UserProfileModel? profile, UserModel? user) {
    _setIfEmpty(_firstNameController, profile?.firstName ?? user?.firstName);
    _setIfEmpty(_lastNameController, profile?.lastName ?? user?.lastName);
    _setPhoneIfEmpty(profile?.phoneNumber ?? user?.phoneNumber);
    _selectedCity ??= _canonicalCity(profile?.city);
  }

  void _tryPrefill() {
    if (!mounted) return;

    final request = ref.read(ownerRegistrationRequestProvider).valueOrNull;
    if (request != null) {
      if (_prefilledFromRequest) return;
      setState(() {
        _prefillFromRequest(request);
        _prefilledFromRequest = true;
      });
      return;
    }

    setState(() {
      _prefillFromProfile(
        ref.read(clientProfileProvider).userProfile,
        ref.read(authProvider).session?.user,
      );
    });
  }

  Future<void> _submit() async {
    final request = ref.read(ownerRegistrationRequestProvider).valueOrNull;

    if (request?.isApproved == true) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final notifier = ref.read(ownerRegistrationMutationProvider.notifier);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phoneNumber = normalizeKzPhone(_phoneController.text) ?? '';
    final email = _emailController.text.trim();
    final city = _selectedCity?.trim() ?? '';
    final message = _messageController.text.trim();

    final isResubmit = request?.isRejected == true;
    final success = request == null || isResubmit
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
        message: request == null || isResubmit
            ? l10n.requestSubmitted
            : l10n.requestUpdated,
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final request = ref.watch(ownerRegistrationRequestProvider).valueOrNull;
    final mutationState = ref.watch(ownerRegistrationMutationProvider);

    final isAccepted = request?.isApproved == true;

    ref.listen<String?>(authProvider.select((auth) => auth.currentUserId), (
      previousUserId,
      nextUserId,
    ) {
      if (previousUserId == nextUserId) return;

      _clearFormForAccountChange();

      if (nextUserId != null) {
        Future.microtask(() {
          if (mounted) {
            return _loadCurrentAccount(nextUserId);
          }
        });
      }
    });

    ref.listen(ownerRegistrationRequestProvider, (previous, next) {
      final previousRequest = previous?.valueOrNull;
      final request = next.valueOrNull;

      if (previousRequest != null && request == null) {
        _clearFormForAccountChange();
      }

      _tryPrefill();
    });

    ref.listen(clientProfileProvider, (previous, next) {
      if (ref.read(ownerRegistrationRequestProvider).valueOrNull != null) {
        return;
      }
      _tryPrefill();
    });

    final submitLabel = request == null
        ? l10n.submitRequest
        : request.isRejected
        ? l10n.resubmitRequest
        : l10n.updateRequest;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const SizedBox(height: 12),
              Text(l10n.joinTeamHint, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(l10n.requestReviewedHint, style: theme.textTheme.bodySmall),
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
              KzPhoneInputField(
                controller: _phoneController,
                label: l10n.phoneNumber,
                hint: l10n.phoneHint,
                icon: Icons.phone_outlined,
                helperText: l10n.ownerContactPhoneHint,
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
              CitySelectField(
                city: _selectedCity,
                isRequired: true,
                service: CitySelectorService.becomeowner,
                onChanged: (city) => setState(() => _selectedCity = city),
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
                  isLoading: mutationState.isLoading,
                  icon: Icons.send_rounded,
                  onPressed: mutationState.isLoading ? null : _submit,
                ),
              ] else ...[
                _AcceptedInfo(theme: theme),
              ],

              SizedBox(height: 40),
            ],
          ),
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

    final adminComment = (request.adminComment ?? '').trim();

    final (title, subtitle, icon, color) = switch (request.parsedStatus) {
      BecomeOwnerRequestStatus.approved => (
        l10n.statusAccepted,
        l10n.statusAcceptedSubtitle,
        Icons.verified_rounded,
        Colors.green,
      ),
      BecomeOwnerRequestStatus.rejected => (
        l10n.statusRejected,
        l10n.statusRejectedSubtitle,
        Icons.error_outline_rounded,
        colors.error,
      ),
      BecomeOwnerRequestStatus.pending => (
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
