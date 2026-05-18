import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/features/user/state/user_profile_provider.dart';
import 'package:go_router/go_router.dart';

Future<void> showEditUsernameSheet(
  BuildContext context,
  WidgetRef ref,
  String? currentUsername,
) {
  final isLocked = currentUsername != null && currentUsername.isNotEmpty;

  final controller = TextEditingController(text: currentUsername ?? '');

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Title
              Text('Set Username', style: textTheme.titleLarge),

              const SizedBox(height: 8),

              /// Info text
              Text(
                isLocked
                    ? 'Username cannot be changed once set.'
                    : 'Choose a username. This can only be set once.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),

              const SizedBox(height: 20),

              /// Username input
              TextField(
                controller: controller,
                enabled: !isLocked,
                textInputAction: TextInputAction.done,
                style: textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'username',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Close'),
                    ),
                  ),

                  if (!isLocked) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final username = controller.text.trim();
                          if (username.length < 3) return;

                          final success = await ref
                              .read(userProfileProvider.notifier)
                              .updateUserName(username);

                          if (success == true && context.mounted) {
                            context.pop();
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
