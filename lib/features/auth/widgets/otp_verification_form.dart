import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/constants/otp_cooldown.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/auth_error_message.dart';
import 'package:prokat/l10n/app_localizations.dart';

import '../widgets/otp_field.dart';

import 'dart:async';

class OtpVerificationForm extends ConsumerStatefulWidget {
  final String phone;
  final Function(String?) onError;

  const OtpVerificationForm({
    super.key,
    required this.phone,
    required this.onError,
  });

  @override
  ConsumerState<OtpVerificationForm> createState() =>
      _OtpVerificationFormState();
}

class _OtpVerificationFormState extends ConsumerState<OtpVerificationForm> {
  final otpController = TextEditingController();
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
    _cooldownTimer?.cancel(); // Cancel timer to prevent leaks or context errors
    otpController.dispose();
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
      if (remaining == 0) _cooldownTimer?.cancel();
    }

    update();
    if (_secondsRemaining > 0) {
      _cooldownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => update(),
      );
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      widget.onError(_l10n.pleaseEnterOtp);
      return;
    }

    if (otp.length != 6) {
      widget.onError(_l10n.otpMustBeSixDigits);
      return;
    }

    widget.onError(null);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(widget.phone, otp);

      if (success != true) {
        widget.onError(_l10n.invalidOrExpiredOtp);
      }
    } catch (e) {
      widget.onError(_l10n.somethingWentWrong);
    }
  }

  // Triggers another OTP transmission through your active Riverpod authProvider
  Future<void> resendOtp() async {
    widget.onError(null);
    try {
      final success = await ref
          .read(authProvider.notifier)
          .requestOtp(widget.phone);

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
    final authState = ref.watch(authProvider);

    ref.listen<DateTime?>(
      authProvider.select((state) => state.otpRetryAt),
      (_, retryAt) => _syncCooldown(retryAt),
    );

    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final isTimerActive = _secondsRemaining > 0;

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          _l10n.otpSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.phone,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 24),
        OtpField(controller: otpController),
        const SizedBox(height: 32),
        ListenableBuilder(
          listenable: otpController,
          builder: (context, _) {
            final temp = otpController.text.trim();
            final canSubmit =
                temp.length == 6 &&
                num.tryParse(temp) != null &&
                !authState.isLoading;

            return PrimaryButton(
              label: authState.isLoading ? _l10n.verifying : _l10n.verifyOtp,
              isLoading: authState.isLoading,
              onPressed: canSubmit ? verifyOtp : null,
            );
          },
        ),
        const SizedBox(height: 24),

        // Consolidated Resend Logic UI Section
        if (isTimerActive) ...[
          // State A: Timer is ticking down
          Text(
            _l10n.otpRetryIn(_secondsRemaining),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ] else ...[
          // State B: Timer reached 0. Actionable Resend Link
          TextButton(
            onPressed: authState.isLoading ? null : resendOtp,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _l10n.didntReceiveCodeResend,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        const SizedBox(
          height: 24,
        ), // Gives clean breathing room before exit action
        // Change Phone Number Section
        Center(
          child: TextButton(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authProvider.notifier).clearOtpSession();
                  },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _l10n.changePhoneNumber,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration
                    .underline, // Subtle distinction from resend text
              ),
            ),
          ),
        ),
      ],
    );
  }
}
