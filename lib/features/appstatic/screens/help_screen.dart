import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/primary_button.dart';
import 'package:prokat/core/widgets/section_title.dart';

final faqs = [
  {
    "q": "How do I rent equipment?",
    "a":
        "Browse available equipment, select your dates, and send a booking request to the owner.",
  },
  {
    "q": "How do I list my equipment?",
    "a":
        "Go to your profile and tap 'Add Equipment'. Fill in details, pricing, and location.",
  },
  {
    "q": "How do payments work?",
    "a":
        "Payments are handled securely through the platform. You’ll see the total before confirming.",
  },
  {
    "q": "Can I cancel a booking?",
    "a":
        "Yes, depending on the owner's cancellation policy shown on the equipment page.",
  },
  {
    "q": "What if equipment is damaged?",
    "a":
        "Report the issue through the app immediately. Our support team will assist you.",
  },
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          "Help & Support",
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        backgroundColor: theme.primaryColor,
      ),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TextField(
                  //   decoration: InputDecoration(
                  //     hintText: "Search help...",
                  //     prefixIcon: Icon(Icons.search),
                  //   ),
                  // ),

                  // const SizedBox(height: 24),
                  SectionTitle(title: "Frequently Asked Questions"),

                  _buildFAQ(),

                  const SizedBox(height: 12),

                  SectionTitle(title: "Need more help?"),

                  _buildHelpOptions(context, theme),

                  PrimaryButton(
                    label: "Contact Support",
                    onPressed: () {
                      _openSupport(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ() {
    return Column(
      children: faqs.map((faq) {
        return ExpansionTile(
          title: Text(faq["q"]!),
          children: [
            Padding(padding: const EdgeInsets.all(12), child: Text(faq["a"]!)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHelpOptions(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _helpTile(
          theme: theme,
          icon: Icons.book_outlined,
          title: "Using Prokat",
          subtitle: "Learn how the platform works",
          onTap: () {},
        ),
        _helpTile(
          theme: theme,
          icon: Icons.payment_outlined,
          title: "Payments & Pricing",
          subtitle: "Fees, payouts, and billing",
          onTap: () {},
        ),
        _helpTile(
          theme: theme,
          icon: Icons.security_outlined,
          title: "Safety & Trust",
          subtitle: "Guidelines and policies",
          onTap: () {},
        ),
        _helpTile(
          theme: theme,
          icon: Icons.person_outline,
          title: "Account Help",
          subtitle: "Login, profile, and settings",
          onTap: () {},
        ),
      ],
    );
  }

  Widget _helpTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceBright,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _openSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Contact Support",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text("Email Support"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text("Live Chat"),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text("Call Us"),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
