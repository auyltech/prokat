import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/utils/format.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/auth/constants/otp_cooldown.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/auth_error_message.dart';
import 'package:prokat/l10n/app_localizations.dart';

class LoginWithPhoneForm extends ConsumerStatefulWidget {
  final Function(String?) onError;

  const LoginWithPhoneForm({super.key, required this.onError});

  @override
  ConsumerState<LoginWithPhoneForm> createState() => _LoginWithPhoneFormState();
}

class _LoginWithPhoneFormState extends ConsumerState<LoginWithPhoneForm> {
  final phoneController = TextEditingController.fromValue(
    kzPhoneEditingValue(null),
  );
  late AppLocalizations _l10n;

  Timer? _cooldownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncCooldown(ref.read(authProvider).otpRetryAt);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    phoneController.dispose();
    super.dispose();
  }

  void _syncCooldown(DateTime? retryAt) {
    _cooldownTimer?.cancel();

    void update() {
      final milliseconds =
          retryAt?.difference(DateTime.now()).inMilliseconds ?? 0;

      final remaining = milliseconds <= 0
          ? 0
          : ((milliseconds + 999) ~/ 1000).clamp(
              0,
              otpCooldownDuration.inSeconds,
            );

      if (!mounted) return;

      if (_secondsRemaining != remaining) {
        setState(() => _secondsRemaining = remaining);
      }
    }

    update();
    if (_secondsRemaining > 0) {
      _cooldownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => update(),
      );
    }
  }

  Future<void> requestOtp() async {
    final fullPhone = normalizeKzPhone(phoneController.text);

    if (fullPhone == null) {
      final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
      widget.onError(
        digits.isEmpty ? _l10n.pleaseEnterPhone : _l10n.validKazakhPhone,
      );
      return;
    }

    widget.onError(null);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .requestOtp(fullPhone);

      if (!success) {
        widget.onError(otpRequestErrorMessage(ref.read(authProvider), _l10n));
      }
    } catch (e) {
      widget.onError(_l10n.somethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);

    ref.listen<DateTime?>(
      authProvider.select((state) => state.otpRetryAt),
      (_, retryAt) => _syncCooldown(retryAt),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourPhoneNumber,
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: -1),
        ),

        Text(
          l10n.otpWhatsAppHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),

        const SizedBox(height: AppDimens.s20$lg),

        AppKzPhoneField(
          title: _l10n.phoneNumber,
          hint: _l10n.phoneHint,
          controller: phoneController,
        ),

        const SizedBox(height: AppDimens.s24$xl),

        ListenableBuilder(
          listenable: phoneController,
          builder: (context, _) {
            final fullPhone = normalizeKzPhone(phoneController.text);
            final cooldownSeconds =
                fullPhone != null && authState.otpCooldownPhone == fullPhone
                ? _secondsRemaining
                : 0;

            final canSubmit =
                fullPhone != null &&
                !authState.isLoading &&
                cooldownSeconds == 0;

            return Column(
              children: [
                AppElevatedButton(
                  title: authState.isLoading ? _l10n.sending : _l10n.sendOtp,
                  isLoading: authState.isLoading,
                  onTap: canSubmit ? requestOtp : null,
                ),
                if (cooldownSeconds > 0) ...[
                  const SizedBox(height: AppDimens.s08$sm),

                  Text(
                    _l10n.otpRetryIn(cooldownSeconds),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
