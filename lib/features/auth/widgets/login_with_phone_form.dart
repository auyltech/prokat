import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/auth_error_message.dart';
import 'package:prokat/features/auth/widgets/phone_input_field.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'otp_verification_form.dart';

class LoginWithPhoneForm extends ConsumerStatefulWidget {
  final Function(String?) onError;

  const LoginWithPhoneForm({super.key, required this.onError});

  @override
  ConsumerState<LoginWithPhoneForm> createState() => _LoginWithPhoneFormState();
}

class _LoginWithPhoneFormState extends ConsumerState<LoginWithPhoneForm> {
  final phoneController = TextEditingController(text: "");
  late AppLocalizations _l10n;

  bool showOtp = false;
  String phone = "";
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
      final remaining = milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
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

  bool isValidKazakhstanPhone(String phone) {
    final regex = RegExp(r'^\+7\d{10}$');
    return regex.hasMatch(phone);
  }

  Future<void> requestOtp() async {
    final rawDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (rawDigits.isEmpty) {
      widget.onError(_l10n.pleaseEnterPhone);
      return;
    }

    final fullPhone = "+7$rawDigits";

    widget.onError(null);

    if (!isValidKazakhstanPhone(fullPhone)) {
      widget.onError(_l10n.validKazakhPhone);
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
    final authState = ref.watch(authProvider);

    ref.listen<DateTime?>(
      authProvider.select((state) => state.otpRetryAt),
      (_, retryAt) => _syncCooldown(retryAt),
    );

    final hasOtpSession =
        authState.otpPhone != null && authState.otpRequestedAt != null;

    if (hasOtpSession) {
      return OtpVerificationForm(
        phone: authState.otpPhone!,
        onError: widget.onError,
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),

        PhoneInputField(label: _l10n.phoneNumber, controller: phoneController),

        const SizedBox(height: 24),

        ListenableBuilder(
          listenable: phoneController,
          builder: (context, _) {
            final rawDigits = phoneController.text.replaceAll(
              RegExp(r'\D'),
              '',
            );
            final fullPhone = "+7$rawDigits";
            final cooldownSeconds = authState.otpCooldownPhone == fullPhone
                ? _secondsRemaining
                : 0;

            final canSubmit =
                isValidKazakhstanPhone(fullPhone) &&
                !authState.isLoading &&
                cooldownSeconds == 0;

            return PrimaryButton(
              label: authState.isLoading
                  ? _l10n.sending
                  : cooldownSeconds > 0
                  ? _l10n.resendOtpIn(cooldownSeconds)
                  : _l10n.sendOtp,
              isLoading: authState.isLoading,
              onPressed: canSubmit ? requestOtp : null,
            );
          },
        ),
      ],
    );
  }
}
