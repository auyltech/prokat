import 'package:flutter/material.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_icon_button.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';

class DemandSurveyAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const DemandSurveyAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 5,
      backgroundColor: theme.cardColor,
      automaticallyImplyLeading: false,
      iconTheme: IconThemeData(color: theme.colorScheme.primary),
      leading: AppIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () {
          if (context.canPop()) {
            context.pop();
          }
        },
      ),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: const [NotificationBadge()],
      actionsPadding: const EdgeInsets.only(right: 16),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.black12, height: 1),
      ),
    );
  }
}
