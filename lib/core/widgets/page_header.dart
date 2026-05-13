import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prokat/core/router/app_routes.dart';

class PageHeader extends StatelessWidget {
  final String? title;
  final Color? primaryColor;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  const PageHeader({
    super.key,
    this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: primaryColor ?? theme.primaryColor,
      // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // 2. SafeArea moves inside the container to push text below the status bar
      child: SafeArea(
        bottom: false,
        child: Stack(
          // Using Stack keeps the title perfectly centered
          alignment: Alignment.centerLeft,
          children: [
            if (showBack)
              IconButton(
                icon: Icon(
                  LucideIcons.chevronLeft,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.push(AppRoutes.dashboard);
                  }
                },
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),

            if (title != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: showBack ? 48.0 : 0,
                  ),
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

            /// Optional trailing widget
            Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
