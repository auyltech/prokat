import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import '../widgets/otp_field.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';

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

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    // 1. Frontend Validation
    if (otp.isEmpty) {
      widget.onError("Please enter the verification code");
      return;
    }

    if (otp.length != 6) {
      widget.onError("The OTP must be 6 digits");
      return;
    }

    // Clear previous errors
    widget.onError(null);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(widget.phone, otp);

      if (success == true) {
        await ref.read(userProfileProvider.notifier).getUserProfile();

        final role = ref.watch(userProfileProvider).userProfile?.role ?? "";

        context.go(
          role.toLowerCase() == "owner"
              ? AppRoutes.ownerDashboard
              : AppRoutes.searchList,
        );
      } else {
        widget.onError("Invalid or expired OTP");
      }
    } catch (e) {
      widget.onError("Something went wrong!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        const SizedBox(height: 20),

        Text(
          "Enter the 6-digit code sent to",
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
          listenable: otpController, // Listens to every keystroke
          builder: (context, _) {
            final temp = otpController.text.trim();

            // Logic is re-evaluated every time the text changes
            final canSubmit =
                temp.length == 6 &&
                num.tryParse(temp) != null &&
                !authState.isLoading;

            return PrimaryButton(
              label: authState.isLoading ? " Verifying..." : "Verify OTP",
              isLoading: authState.isLoading,
              onPressed: canSubmit ? verifyOtp : null,
            );
          },
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await ref.read(authProvider.notifier).clearOtpSession();
                  },
            child: Text(
              "Change Phone Number",
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
