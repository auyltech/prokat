import 'package:flutter/material.dart';
import 'package:prokat/l10n/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(l10n),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildLegalSection(
                    title: l10n.rentalEligibilityTitle,
                    summary: l10n.rentalEligibilitySummary,
                    content: l10n.rentalEligibilityContent,
                  ),
                  _buildLegalSection(
                    title: l10n.damageLiabilityTitle,
                    summary: l10n.damageLiabilitySummary,
                    content: l10n.damageLiabilityContent,
                  ),
                  _buildLegalSection(
                    title: l10n.lateReturnsTitle,
                    summary: l10n.lateReturnsSummary,
                    content: l10n.lateReturnsContent,
                  ),
                  _buildLegalSection(
                    title: l10n.cancellationsTitle,
                    summary: l10n.cancellationsSummary,
                    content: l10n.cancellationsContent,
                  ),
                  const SizedBox(height: 20),
                  _buildAcceptanceNotice(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Icon(Icons.gavel_rounded, size: 48, color: Colors.blueGrey),
          const SizedBox(height: 16),
          Text(
            l10n.legalStuff,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.lastUpdated,
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
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
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

  Widget _buildAcceptanceNotice(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        l10n.termsAcceptanceNotice,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }
}
