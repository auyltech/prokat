import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
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
  static const int _cooldownDurationSeconds = 60; // 1-minute default cooldown

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

  // Calculates remaining seconds based on when the OTP session started
  void _updateTimerState(DateTime requestedAt) {
    final difference = DateTime.now().difference(requestedAt).inSeconds;
    final remaining = _cooldownDurationSeconds - difference;

    if (remaining > 0) {
      if (_secondsRemaining != remaining) {
        setState(() {
          _secondsRemaining = remaining;
        });
      }
      _startTimerLoop(requestedAt);
    } else {
      if (_secondsRemaining != 0) {
        setState(() {
          _secondsRemaining = 0;
        });
        _cooldownTimer?.cancel();
      }
    }
  }

  void _startTimerLoop(DateTime requestedAt) {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final difference = DateTime.now().difference(requestedAt).inSeconds;
      final remaining = _cooldownDurationSeconds - difference;

      if (remaining <= 0) {
        setState(() {
          _secondsRemaining = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining = remaining;
        });
      }
    });
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
        widget.onError("Invalid or expired OTP");
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
        widget.onError(_l10n.failedSendOtp);
      }
    } catch (e) {
      widget.onError(_l10n.somethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    // Sync state time from your global provider context layer
    if (authState.otpRequestedAt != null) {
      _updateTimerState(authState.otpRequestedAt!);
    }

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

        // Cooldown Action Section
        if (isTimerActive)
          Text(
            'Resend OTP in $_secondsRemaining seconds',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          TextButton(
            onPressed: authState.isLoading ? null : resendOtp,
            child: Text(
              "Resend OTP", // Make sure to add "resendOtp" to your app_en.arb
              style: theme.textTheme.labelLarge?.copyWith(
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authProvider.notifier).clearOtpSession();
                  },
            child: Text(
              _l10n.changePhoneNumber,
              style: theme.textTheme.labelLarge?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
