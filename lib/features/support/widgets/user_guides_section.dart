import 'package:flutter/material.dart';
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
    return Column(
      children: guides.map((guide) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UserGuideTile(
            guide: guide,
            locale: currentLocale,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserGuideScreen(
                    guide: guide,
                    currentLocale: currentLocale,
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
