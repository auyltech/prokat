import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/utils/localized_city.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/core/widgets/input_field.dart';
import 'package:prokat/core/widgets/kz_phone_input_field.dart';
import 'package:prokat/core/widgets/moderation_status_card.dart';
import 'package:prokat/core/widgets/shake_on_tick.dart';
import 'package:prokat/features/appstartup/app_startup_provider.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/locations/state/location_provider.dart';
import 'package:prokat/features/owner/models/registration_request_model.dart';
import 'package:prokat/features/owner/state/owner_registration_provider.dart';
import 'package:prokat/features/auth/models/user_model.dart';
import 'package:prokat/features/user/models/user_profile_model.dart';
import 'package:prokat/features/user/state/client_profile_provider.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
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
  final _messageController = TextEditingController();

  String? _selectedCity;
  bool _prefilledFromRequest = false;
  int _shakeTick = 0;

  void _clearFormForAccountChange() {
    _formKey.currentState?.reset();

    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.value = kzPhoneEditingValue(null);
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
    if (_redirectIfOwnerApplicationResolved()) return;

    await ref.read(clientProfileProvider.notifier).refreshIfStale();

    if (!mounted || ref.read(authProvider).currentUserId != userId) {
      return;
    }

    await ref.read(ownerRegistrationRequestProvider.notifier).refreshIfStale();
    if (!mounted || ref.read(authProvider).currentUserId != userId) {
      return;
    }
    if (_redirectIfOwnerApplicationResolved()) return;
    if (mounted) _tryPrefill();
  }

  bool _redirectIfOwnerApplicationResolved() {
    if (!mounted) return false;

    final request = ref.read(ownerRegistrationRequestProvider).valueOrNull;
    final isAcceptedOwner =
        ref.read(authProvider).isOwner || request?.isApproved == true;

    if (isAcceptedOwner) {
      unawaited(ref.read(appStartupProvider.notifier).setOwnerMode());
      context.go(AppRoutes.ownerProfile);
      return true;
    }

    if (request != null && request.isPending) {
      context.go(AppRoutes.clientProfile);
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final userId = ref.read(authProvider).currentUserId;

      if (userId != null) {
        unawaited(_loadCurrentAccount(userId));
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
    return canonicalCity(
          city,
          catalogCityKeys(ref.read(catalogProvider).valueOrNull),
        ) ??
        _nonEmpty(city);
  }

  void _prefillFromRequest(RegistrationRequestModel request) {
    _firstNameController.text = _nonEmpty(request.firstName) ?? '';
    _lastNameController.text = _nonEmpty(request.lastName) ?? '';
    _applyPhone(request.phoneNumber);
    _selectedCity = _canonicalCity(request.city);
    _messageController.text = _nonEmpty(request.message) ?? '';
  }

  void _prefillFromProfile(UserProfileModel? profile, UserModel? user) {
    _setIfEmpty(_firstNameController, profile?.firstName ?? user?.firstName);
    _setIfEmpty(_lastNameController, profile?.lastName ?? user?.lastName);
    _setPhoneIfEmpty(profile?.phoneNumber ?? user?.phoneNumber);
    _selectedCity ??= _canonicalCity(profile?.city);
    _selectedCity ??= _canonicalCity(ref.read(locationProvider).city);
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

    if (request != null && !request.isRejected) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phoneNumber = normalizeKzPhone(_phoneController.text);
    final city = _selectedCity?.trim() ?? '';
    final message = _messageController.text.trim();

    final hasMissing =
        firstName.isEmpty ||
        lastName.isEmpty ||
        phoneNumber == null ||
        city.isEmpty ||
        message.isEmpty;

    if (hasMissing) {
      setState(() => _shakeTick++);
      return;
    }

    final notifier = ref.read(ownerRegistrationMutationProvider.notifier);

    final success = await notifier.createOwnerRegistrationRequest(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      city: city,
      message: message,
    );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    if (success) {
      AppToast.show(message: l10n.requestSubmitted, type: AppToastType.success);
      if (context.canPop()) context.pop();
      return;
    }

    AppToast.show(
      message:
          ref.read(ownerRegistrationMutationProvider).error ??
          l10n.somethingWentWrongTryAgain,
      type: AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final request = ref.watch(ownerRegistrationRequestProvider).valueOrNull;
    final mutationState = ref.watch(ownerRegistrationMutationProvider);

    final isAccepted = request?.isApproved == true;
    final isReadOnly = request != null && !request.isRejected;
    final canSubmit = request == null || request.isRejected;

    ref.listen<String?>(authProvider.select((auth) => auth.currentUserId), (
      previousUserId,
      nextUserId,
    ) {
      if (previousUserId == nextUserId) return;

      _clearFormForAccountChange();

      if (nextUserId != null) {
        unawaited(
          Future.microtask(() {
            if (mounted) {
              return _loadCurrentAccount(nextUserId);
            }
          }),
        );
      }
    });

    ref.listen(ownerRegistrationRequestProvider, (previous, next) {
      final previousRequest = previous?.valueOrNull;
      final request = next.valueOrNull;

      if (previousRequest != null && request == null) {
        _clearFormForAccountChange();
      }

      if (_redirectIfOwnerApplicationResolved()) return;
      _tryPrefill();
    });

    ref.listen(clientProfileProvider, (previous, next) {
      if (ref.read(ownerRegistrationRequestProvider).valueOrNull != null) {
        return;
      }
      _tryPrefill();
    });

    final submitLabel = request?.isRejected == true
        ? l10n.resubmitRequest
        : l10n.submitRequest;

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
              const SizedBox(height: 16),
              _OwnerCityChip(
                city: _selectedCity,
                enabled: !isReadOnly,
                shakeTick: (_selectedCity ?? '').trim().isEmpty
                    ? _shakeTick
                    : 0,
                onChanged: (city) => setState(() => _selectedCity = city),
              ),
              const SizedBox(height: 16),

              if (request != null) _StatusCard(request: request),
              if (request != null) const SizedBox(height: 16),

              InputField(
                controller: _firstNameController,
                label: l10n.firstName,
                hint: l10n.firstNameHint,
                icon: Icons.person_outline,
                readOnly: isReadOnly,
                isRequired: true,
                requiredHintText: l10n.requiredInParens,
                requiredHintMuted: true,
                showFieldErrors: false,
                shakeTick: _firstNameController.text.trim().isEmpty
                    ? _shakeTick
                    : 0,
              ),

              const SizedBox(height: 8),

              InputField(
                controller: _lastNameController,
                label: l10n.lastName,
                hint: l10n.lastNameHint,
                icon: Icons.person_outline,
                readOnly: isReadOnly,
                isRequired: true,
                requiredHintText: l10n.requiredInParens,
                requiredHintMuted: true,
                showFieldErrors: false,
                shakeTick: _lastNameController.text.trim().isEmpty
                    ? _shakeTick
                    : 0,
              ),

              const SizedBox(height: 8),
              KzPhoneInputField(
                controller: _phoneController,
                label: l10n.phoneNumber,
                hint: l10n.phoneHint,
                icon: Icons.phone_outlined,
                helperText: l10n.ownerContactPhoneHint,
                readOnly: isReadOnly,
                isRequired: true,
                requiredHintText: l10n.requiredInParens,
                requiredHintMuted: true,
                showFieldErrors: false,
                shakeTick: normalizeKzPhone(_phoneController.text) == null
                    ? _shakeTick
                    : 0,
              ),

              const SizedBox(height: 8),
              InputField(
                controller: _messageController,
                label: l10n.message,
                hint: l10n.messageHint,
                icon: Icons.message_outlined,
                keyboardType: TextInputType.multiline,
                isLast: true,
                readOnly: isReadOnly,
                isRequired: true,
                requiredHintText: l10n.requiredInParens,
                requiredHintMuted: true,
                showFieldErrors: false,
                maxLines: 4,
                hintMaxLines: 4,
                shakeTick: _messageController.text.trim().isEmpty
                    ? _shakeTick
                    : 0,
              ),

              if (canSubmit) ...[
                const SizedBox(height: 16),
                AppElevatedButton(
                  title: submitLabel,
                  isLoading: mutationState.isLoading,
                  prefix: const Icon(Icons.send_rounded),
                  onTap: mutationState.isLoading ? null : _submit,
                ),
              ] else if (isAccepted) ...[
                _AcceptedInfo(theme: theme),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerCityChip extends ConsumerWidget {
  final String? city;
  final bool enabled;
  final int shakeTick;
  final ValueChanged<String> onChanged;

  const _OwnerCityChip({
    required this.city,
    required this.enabled,
    required this.shakeTick,
    required this.onChanged,
  });

  Future<void> _pickCity(BuildContext context, WidgetRef ref) async {
    final selected = await CityPickerSheet.show(
      context: context,
      service: CitySelectorService.becomeowner,
      highlightedCity: city,
    );
    if (selected == null || selected.isEmpty) return;

    final next =
        canonicalCity(
          selected,
          catalogCityKeys(ref.read(catalogProvider).valueOrNull),
        ) ??
        selected;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final hasCity = (city ?? '').trim().isNotEmpty;
    final showError = shakeTick > 0 && !hasCity;
    final label = hasCity
        ? catalogCityLabelOf(ref, context, city)
        : l10n.selectCity;

    return ShakeOnTick(
      tick: shakeTick,
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: enabled ? () => _pickCity(context, ref) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: showError
                    ? colors.error
                    : colors.outline.withValues(alpha: 0.6),
                width: showError ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: colors.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ],
            ),
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final comment = (request.adminComment ?? '').trim();

    return switch (request.parsedStatus) {
      BecomeOwnerRequestStatus.approved => ModerationStatusCard(
        title: l10n.statusAccepted,
        subtitle: l10n.statusAcceptedSubtitle,
        icon: Icons.verified_rounded,
        color: Colors.green,
      ),
      BecomeOwnerRequestStatus.rejected => ModerationStatusCard(
        title: l10n.statusRejected,
        subtitle: comment.isEmpty
            ? l10n.statusRejectedNoComment
            : l10n.statusRejectedReviewHint,
        icon: Icons.error_outline_rounded,
        color: colors.error,
        detail: comment.isEmpty ? null : comment,
      ),
      BecomeOwnerRequestStatus.pending => ModerationStatusCard(
        title: l10n.statusUnderReview,
        subtitle: l10n.statusUnderReviewSubtitle,
        icon: Icons.hourglass_top_rounded,
        color: colors.primary,
      ),
    };
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
