import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/features/auth/widgets/phone_input_field.dart';
import 'otp_verification_form.dart';

class LoginWithPhoneForm extends ConsumerStatefulWidget {
  final Function(String?) onError;

  const LoginWithPhoneForm({super.key, required this.onError});

  @override
  ConsumerState<LoginWithPhoneForm> createState() => _LoginWithPhoneFormState();
}

class _LoginWithPhoneFormState extends ConsumerState<LoginWithPhoneForm> {
  final phoneController = TextEditingController(text: "");

  bool showOtp = false;
  String phone = "";

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  bool isValidKazakhstanPhone(String phone) {
    // Matches +7 followed by 10 digits
    final regex = RegExp(r'^\+7\d{10}$');
    return regex.hasMatch(phone);
  }

  Future<void> requestOtp() async {
    final rawDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (rawDigits.isEmpty) {
      widget.onError("Please enter your phone number");
      return;
    }

    final fullPhone = "+7$rawDigits";

    widget.onError(null);

    if (!isValidKazakhstanPhone(fullPhone)) {
      widget.onError("Enter a valid Kazakhstan phone (+7 XXX XXX XXXX)");
      return;
    }

    // Clear previous errors
    widget.onError(null);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .requestOtp(fullPhone);

      if (!success) {
        widget.onError("Failed to send OTP. Please try again.");
      }
    } catch (e) {
      widget.onError("Something went wrong!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final hasOtpSession =
        authState.otpPhone != null && authState.otpRequestedAt != null;

    if (hasOtpSession) {
      // Passing onError to the next form as well
      return OtpVerificationForm(
        phone: authState.otpPhone!,
        onError: widget.onError,
      );
    }

    return Column(
      children: [
        const SizedBox(height: 20),

        PhoneInputField(label: "Phone Number", controller: phoneController),

        const SizedBox(height: 24),

        ListenableBuilder(
          listenable: phoneController, // Listens to every keystroke
          builder: (context, _) {
            final rawDigits = phoneController.text.replaceAll(
              RegExp(r'\D'),
              '',
            );
            final fullPhone = "+7$rawDigits";

            // Logic is re-evaluated every time the text changes
            final canSubmit =
                !isValidKazakhstanPhone(fullPhone) && !authState.isLoading;

            return PrimaryButton(
              label: authState.isLoading ? "Sending..." : "Send Otp",
              isLoading: authState.isLoading,
              onPressed: canSubmit ? requestOtp : null,
            );
          },
        ),
      ],
    );
  }
}
