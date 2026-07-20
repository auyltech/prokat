import 'package:flutter/material.dart';
import 'package:prokat/features/support/models/faq_model.dart';

class FaqTile extends StatelessWidget {
  final FaqModel faq;
  final String currentLocale;

  const FaqTile({super.key, required this.faq, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    final tr = faq.translation(currentLocale);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 1.2)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 16.0),
        iconColor: const Color(0xFF004699),
        collapsedIconColor: Colors.grey,
        title: Text(
          tr.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        children: [
          Text(
            tr.answer,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
