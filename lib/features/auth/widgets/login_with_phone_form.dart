import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
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
        widget.onError(_l10n.failedSendOtp);
      }
    } catch (e) {
      widget.onError(_l10n.somethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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

            final canSubmit =
                isValidKazakhstanPhone(fullPhone) && !authState.isLoading;

            return PrimaryButton(
              label: authState.isLoading ? _l10n.sending : _l10n.sendOtp,
              isLoading: authState.isLoading,
              onPressed: canSubmit ? requestOtp : null,
            );
          },
        ),
      ],
    );
  }
}
