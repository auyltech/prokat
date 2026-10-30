import 'package:flutter/material.dart';

class CompactMessageText extends StatelessWidget {
  const CompactMessageText({
    super.key,
    required this.text,
    required this.style,
    required this.metadata,
  });
  final String text;
  final TextStyle style;
  final Widget metadata;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: text),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: MediaQuery.withNoTextScaling(
            child: IntrinsicWidth(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: metadata,
              ),
            ),
          ),
        ),
      ],
    ),
    style: style,
  );
}
