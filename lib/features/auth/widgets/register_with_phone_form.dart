import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/auth_button.dart';
import 'package:prokat/features/auth/widgets/auth_text_field.dart';
import 'package:prokat/features/auth/widgets/otp_verification_form.dart';
import 'package:prokat/l10n/app_localizations.dart';

class RegisterWithPhoneForm extends ConsumerStatefulWidget {
  final Function(String?) onError;

  const RegisterWithPhoneForm({super.key, required this.onError});

  @override
  ConsumerState<RegisterWithPhoneForm> createState() =>
      _RegisterWithPhoneFormState();
}

class _RegisterWithPhoneFormState extends ConsumerState<RegisterWithPhoneForm> {
  final phoneController = TextEditingController(text: "+7");
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
    return RegExp(r'^\+7\d{10}$').hasMatch(phone);
  }

  Future<void> requestOtp() async {
    final value = phoneController.text.trim();

    if (value == "+7" || value.isEmpty) {
      widget.onError(_l10n.pleaseEnterPhone);
      return;
    }

    if (!isValidKazakhstanPhone(value)) {
      widget.onError(_l10n.validKazakhPhone);
      return;
    }

    widget.onError(null);

    try {
      final success = await ref.read(authProvider.notifier).requestOtp(value);

      if (success) {
        setState(() {
          phone = value;
          showOtp = true;
        });
      } else {
        widget.onError(_l10n.registrationFailed);
      }
    } catch (e) {
      widget.onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (showOtp) {
      return OtpVerificationForm(phone: phone, onError: widget.onError);
    }

    return Column(
      children: [
        const SizedBox(height: 20),

        AuthTextField(
          label: _l10n.phoneNumber,
          icon: Icons.phone_android_outlined,
          controller: phoneController,
          keyboardType: TextInputType.phone,
        ),

        const SizedBox(height: 24),

        AuthButton(
          loading: authState.isLoading,
          text: _l10n.sendCode,
          loadingText: _l10n.sending,
          onPressed: requestOtp,
        ),
      ],
    );
  }
}
