import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/features/auth/providers/auth_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';
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
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
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

      if (success == true) {
        await ref.read(userProfileProvider.notifier).getUserProfile();

        if (!mounted) return;
        final role = ref.read(userProfileProvider).userProfile?.role ?? "";

        context.go(
          role.toLowerCase() == "owner"
              ? AppRoutes.ownerDashboard
              : AppRoutes.searchList,
        );
      } else {
        widget.onError(_l10n.invalidExpiredOtp);
      }
    } catch (e) {
      widget.onError(_l10n.somethingWentWrong);
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

        const SizedBox(height: 16),

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
