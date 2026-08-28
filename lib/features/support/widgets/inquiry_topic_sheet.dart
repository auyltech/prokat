import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prokat/features/support/models/contact_inquiry_topic.dart';
import 'package:prokat/l10n/app_localizations.dart';

class InquiryTopicSheet extends StatefulWidget {
  final ContactInquiryTopic? selectedTopic;

  const InquiryTopicSheet({super.key, this.selectedTopic});

  static Future<ContactInquiryTopic?> show(
    BuildContext context, {
    ContactInquiryTopic? selectedTopic,
  }) {
    return showModalBottomSheet<ContactInquiryTopic>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return InquiryTopicSheet(selectedTopic: selectedTopic);
      },
    );
  }

  @override
  State<InquiryTopicSheet> createState() => _InquiryTopicSheetState();
}

class _InquiryTopicSheetState extends State<InquiryTopicSheet> {
  final _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedContext = _selectedKey.currentContext;
      if (selectedContext == null || !selectedContext.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          selectedContext,
          alignment: 0.3,
          duration: const Duration(milliseconds: 200),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const topics = ContactInquiryTopic.values;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 24,
            top: 12,
            left: 24,
            right: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.selectInquiryTopic,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final isSelected = topic == widget.selectedTopic;
                    return _TopicTile(
                      key: isSelected ? _selectedKey : null,
                      title: topic.localizedLabel(l10n),
                      icon: _iconFor(topic),
                      isSelected: isSelected,
                      onTap: () => Navigator.pop(context, topic),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicTile({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        child: Icon(
          icon,
          color: isSelected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurface,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
    );
  }
}

IconData _iconFor(ContactInquiryTopic topic) {
  return switch (topic) {
    ContactInquiryTopic.general => Icons.chat_bubble_outline,
    ContactInquiryTopic.support => Icons.support_agent_outlined,
    ContactInquiryTopic.bugReport => Icons.bug_report_outlined,
    ContactInquiryTopic.featureRequest => Icons.lightbulb_outline,
    ContactInquiryTopic.sales => Icons.storefront_outlined,
    ContactInquiryTopic.partnership => Icons.handshake_outlined,
    ContactInquiryTopic.billing => Icons.receipt_long_outlined,
    ContactInquiryTopic.callMe => Icons.phone_callback_outlined,
    ContactInquiryTopic.accountDeletion => Icons.person_off_outlined,
    ContactInquiryTopic.accountRecovery => Icons.lock_reset_outlined,
    ContactInquiryTopic.accountIssue => Icons.manage_accounts_outlined,
    ContactInquiryTopic.other => Icons.more_horiz,
  };
}
