import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/core/theme/prokat_flow_scope.dart';
import 'package:prokat/core/theme/prokat_flow_palette.dart';
import 'package:prokat/features/support/models/user_guide.dart';
import 'package:prokat/features/support/screens/user_guide_screen.dart';
import 'package:prokat/features/support/widgets/user_guide_tile.dart';

class UserGuidesSection extends StatelessWidget {
  const UserGuidesSection({
    super.key,
    required this.guides,
    required this.currentLocale,
  });

  final List<UserGuide> guides;
  final String currentLocale;

  @override
  Widget build(BuildContext context) {
    final flow = ProkatFlowScope.maybeOf(context);
    return Column(
      children: guides.where((guide) => guide.isPublished).map((guide) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UserGuideTile(
            guide: guide,
            locale: currentLocale,
            onTap: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (routeContext) => InheritedTheme.captureAll(
                      context,
                      ProkatFlowScope(
                        palette: flow ?? ProkatFlowPalette.of(context),
                        enabled: flow != null,
                        child: UserGuideScreen(
                          guide: guide,
                          currentLocale: currentLocale,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
