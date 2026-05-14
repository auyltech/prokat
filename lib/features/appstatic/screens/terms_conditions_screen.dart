import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          "Terms & Conditions",
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildLegalSection(
                    title: '1. Rental Eligibility',
                    summary:
                        'You must be 18+ and have a valid ID to rent heavy machinery.',
                    content:
                        'By using this app, you represent that you are at least 18 years of age and possess the legal authority to enter into this agreement. Certain high-value equipment may require additional verification or specialized licenses.',
                  ),
                  _buildLegalSection(
                    title: '2. Damage & Liability',
                    summary:
                        'You are responsible for the gear while you have it.',
                    content:
                        'Equipment must be returned in the condition it was received. You accept full responsibility for any damage, loss, or theft. Ordinary wear and tear is accepted, but negligence (e.g., exposing electronics to rain) is not covered.',
                  ),
                  _buildLegalSection(
                    title: '3. Late Returns & Fees',
                    summary: 'Return it on time or extra daily rates apply.',
                    content:
                        'Late returns disrupt other users. If equipment is not returned by the agreed deadline, you will be charged the daily rental rate for every 24-hour period (or part thereof) until the item is returned.',
                  ),
                  _buildLegalSection(
                    title: '4. Cancellations',
                    summary: 'Full refund if cancelled 24 hours in advance.',
                    content:
                        'Cancellations made within 24 hours of the rental start time may be subject to a 50% convenience fee. No-shows will be charged the full rental amount.',
                  ),
                  const SizedBox(height: 20),
                  _buildAcceptanceNotice(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Icon(Icons.gavel_rounded, size: 48, color: Colors.blueGrey),
          const SizedBox(height: 16),
          const Text(
            'The Legal Stuff',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: May 2026',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection({
    required String title,
    required String summary,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    summary,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'By continuing to use the Equipment Rental App, you acknowledge that you have read and agree to be bound by these terms.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }
}
